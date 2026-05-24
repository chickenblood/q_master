from __future__ import annotations

import argparse
import asyncio
from pathlib import Path
from typing import Protocol

from playwright.async_api import Download, Locator, Page, TimeoutError, async_playwright


EXICON_URL = 'https://codex.f3nation.com/exicon'


class _SearchSurface(Protocol):
    def get_by_role(self, role: str, name: str | None = None) -> Locator: ...
    def get_by_text(self, text: str, exact: bool | None = None) -> Locator: ...


async def _dismiss_cookie_banner(page: Page) -> None:
    candidates = [
        page.get_by_role('button', name='Accept essential'),
        page.get_by_role('button', name='Accept all'),
        page.get_by_text('Accept essential', exact=True),
        page.get_by_text('Accept all', exact=True),
    ]

    for candidate in candidates:
        try:
            await candidate.first.click(timeout=1_500)
            return
        except TimeoutError:
            continue
        except Exception:
            continue


async def _wait_for_export_control(surface: _SearchSurface) -> None:
    await surface.get_by_text('Export CSV', exact=False).first.wait_for(
        state='visible',
        timeout=30_000,
    )


async def _trigger_download(surface: _SearchSurface, page: Page) -> Download:
    export_candidates = [
        surface.get_by_role('button', name='Export CSV'),
        surface.get_by_role('link', name='Export CSV'),
        surface.get_by_text('Export CSV', exact=False),
    ]

    last_error: Exception | None = None
    for candidate in export_candidates:
        try:
            async with page.expect_download(timeout=20_000) as download_info:
                await candidate.first.click(timeout=5_000)
            return await download_info.value
        except Exception as error:
            last_error = error

    raise RuntimeError('Unable to trigger Export CSV download') from last_error


async def export_csv(output_path: Path, *, headed: bool) -> Path:
    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=not headed)
        context = await browser.new_context(accept_downloads=True)
        page = await context.new_page()

        try:
            await page.goto(EXICON_URL, wait_until='domcontentloaded', timeout=60_000)
            await _dismiss_cookie_banner(page)
            await _wait_for_export_control(page)
            download = await _trigger_download(page, page)
            await download.save_as(str(output_path))
            return output_path
        finally:
            await context.close()
            await browser.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Download the public F3 Nation Exicon CSV export.',
    )
    parser.add_argument(
        '--output',
        default='exicon_export.csv',
        help='Path to write the downloaded CSV file.',
    )
    parser.add_argument(
        '--headed',
        action='store_true',
        help='Run Chromium with a visible window for debugging.',
    )
    args = parser.parse_args()

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    exported_path = asyncio.run(export_csv(output_path, headed=args.headed))
    print(exported_path)


if __name__ == '__main__':
    main()
