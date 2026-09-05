# PDF Korean Translator Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS-first local PDF translator that preserves the original page appearance, overlays selectable Korean text, and falls back to DOCX/TXT/Markdown when PDF layout quality is not good enough.

**Architecture:** Use Poppler binaries for PDF inspection, page rendering, and text-coordinate extraction. Keep the original page as a raster background, cover detected source-text regions with white or translucent boxes, then draw embedded Korean text as a real PDF text layer. Treat horizontal body text, vertical text, and notes as separate layout classes so mixed Japanese/English documents remain readable.

**Tech Stack:** Python 3.11+, FastAPI, pypdf, reportlab, python-docx, Pillow, lxml or BeautifulSoup, httpx, bundled Poppler binaries (`pdfinfo`, `pdftoppm`, `pdftotext`), embedded Korean TTF/OTF font, React, Vite, TypeScript, Vitest.

---

## Product Decisions

- Source PDFs are mostly selectable-text Japanese or English documents and novels.
- Images and illustrations should remain visually preserved.
- Output language is always Korean.
- Korean text in the generated PDF must be selectable and copyable.
- Default output keeps the original page size.
- Horizontal body text is translated in place.
- Vertical text and note-like blocks are translated into Korean-friendly bottom or right note areas.
- If note/vertical translation does not fit on the original page, the app offers either an added notes page or an expanded page option.
- First supported runtime is macOS because the current bundled Poppler binaries are macOS binaries.
- Windows/Linux can be added later by bundling OS-specific Poppler binaries and switching paths by platform.
- Fake translation is allowed only in unit tests. The MVP must include one configured production translation provider before the pipeline is considered complete.

## Directory Layout

Create the translator as a separate local app so it does not disturb the existing Flutter portfolio.

```text
apps/pdf-translator/
  backend/
    pyproject.toml
    README.md
    src/pdf_translator/
      __init__.py
      api.py
      cli.py
      config.py
      poppler.py
      models.py
      bbox_parser.py
      block_classifier.py
      translator.py
      providers/
        __init__.py
        external_json.py
      layout.py
      pdf_renderer.py
      fallback_outputs.py
      job_store.py
      assets/fonts/NotoSansKR-Regular.ttf
      vendor/poppler/macos-arm64/bin/.gitkeep
    tests/
      fixtures/
        actual_poppler_bbox.html
        fonts/
          NotoSansKR-Regular.ttf
      test_bbox_parser.py
      test_block_classifier.py
      test_external_translator.py
      test_layout.py
      test_pdf_renderer.py
      test_pipeline.py
  frontend/
    package.json
    vitest.config.ts
    index.html
    src/
      App.tsx
      api.ts
      test/setup.ts
      components/
      styles.css
```

## Output Strategy

1. Run `pdfinfo` to read page count, page dimensions, encryption status, and basic metadata.
2. Run `pdftoppm` to render each original page to an image background.
3. Run `pdftotext -bbox-layout` to extract page, block, line, and word coordinates.
4. Parse the Poppler XHTML output into normalized Python models.
5. Classify blocks as `body_horizontal`, `note_or_vertical`, `ignore`, or `unknown`.
6. Translate text blocks to Korean with stable block IDs.
7. Generate a new PDF:
   - draw the original page image as the background,
   - cover original source-text blocks with white or translucent rectangles,
   - draw translated Korean body text in place,
   - draw note markers such as `[1]` near covered note/vertical source areas,
   - draw Korean note translations in bottom or right note zones,
   - embed a Korean font so text selection and copy-paste work.
8. Generate DOCX, TXT, and Markdown fallbacks from the same translated block manifest.
9. Validate the output PDF by extracting text from it with `pypdf` or Poppler and checking that Korean text is present.

## Required Fixtures, Fonts, and Binary Policy

- Treat `apps/pdf-translator/backend/src/pdf_translator/vendor/poppler` as the Poppler bundle root.
- Use `PDF_TRANSLATOR_POPPLER_ROOT=/absolute/path/to/vendor/poppler` for integration tests and local overrides.
- Under the bundle root, binaries live at `<platform-key>/bin/pdfinfo`, `<platform-key>/bin/pdftoppm`, and `<platform-key>/bin/pdftotext`.
- Keep `PDF_TRANSLATOR_POPPLER_BIN` out of the MVP unless direct-bin override support is explicitly implemented and tested.
- Add a Korean-capable font for rendering and tests. Prefer `NotoSansKR-Regular.ttf` or another redistributable Korean font, and document its license in `apps/pdf-translator/THIRD_PARTY_NOTICES.md`.
- Add at least one `actual_poppler_bbox.html` fixture captured from a real `pdftotext -bbox-layout` run, not only hand-written simplified HTML.
- Any production provider that calls an external translation API must be behind a provider interface and tested with mocked HTTP responses. Do not hardcode a provider directly in the layout or rendering pipeline.

## Task 1: Create Python Backend Skeleton

**Files:**
- Create: `apps/pdf-translator/backend/pyproject.toml`
- Create: `apps/pdf-translator/backend/README.md`
- Create: `apps/pdf-translator/backend/src/pdf_translator/__init__.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/models.py`
- Create: `apps/pdf-translator/backend/tests/`

**Step 1: Write the failing import smoke test**

```python
# apps/pdf-translator/backend/tests/test_imports.py
from pdf_translator.models import PdfJobSettings


def test_imports_package_models():
    settings = PdfJobSettings(source_language="auto", target_language="ko")
    assert settings.target_language == "ko"
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_imports.py -v
```

Expected: FAIL because the package and model do not exist yet.

**Step 3: Add package metadata and minimal models**

Use dataclasses for stable internal contracts and add a complete editable-install setup so every later `pytest` command has the required dependencies.

```toml
# apps/pdf-translator/backend/pyproject.toml
[build-system]
requires = ["setuptools>=69", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "pdf-korean-translator"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.110",
  "httpx>=0.27",
  "lxml>=5.0",
  "pillow>=10.0",
  "pypdf>=4.0",
  "python-docx>=1.1",
  "python-multipart>=0.0.9",
  "reportlab>=4.0",
  "uvicorn>=0.27",
]

[project.optional-dependencies]
dev = [
  "pytest>=8.0",
  "pytest-httpx>=0.30",
  "ruff>=0.5",
]

[project.scripts]
pdf-translator = "pdf_translator.cli:main"

[tool.setuptools.packages.find]
where = ["src"]
```

```python
# apps/pdf-translator/backend/src/pdf_translator/models.py
from dataclasses import dataclass
from enum import Enum


class BlockKind(str, Enum):
    BODY_HORIZONTAL = "body_horizontal"
    NOTE_OR_VERTICAL = "note_or_vertical"
    IGNORE = "ignore"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class PdfJobSettings:
    source_language: str = "auto"
    target_language: str = "ko"
    note_overflow_policy: str = "notes_page"
    cover_opacity: float = 1.0
```

**Step 4: Run test to verify it passes**

Run:

```bash
cd apps/pdf-translator/backend
python -m pip install -e ".[dev]"
pytest tests/test_imports.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend
git commit -m "feat: scaffold pdf translator backend"
```

## Task 2: Add Poppler Binary Adapter

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/config.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/poppler.py`
- Create: `apps/pdf-translator/backend/tests/test_poppler.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/vendor/poppler/macos-arm64/bin/.gitkeep`
- Create: `apps/pdf-translator/THIRD_PARTY_NOTICES.md`

**Step 1: Write tests for binary path resolution**

```python
# apps/pdf-translator/backend/tests/test_poppler.py
from pathlib import Path

from pdf_translator.poppler import PopplerPaths


def test_poppler_paths_resolve_macos_arm64_bundle():
    root = Path("/tmp/fake-poppler")
    paths = PopplerPaths.from_bundle_root(root, platform_key="macos-arm64")

    assert paths.pdfinfo == root / "macos-arm64" / "bin" / "pdfinfo"
    assert paths.pdftoppm == root / "macos-arm64" / "bin" / "pdftoppm"
    assert paths.pdftotext == root / "macos-arm64" / "bin" / "pdftotext"
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_poppler.py -v
```

Expected: FAIL because `PopplerPaths` does not exist.

**Step 3: Implement Poppler command wrapper**

Implement:

- `PopplerPaths`
- `PopplerRunner` protocol
- `SubprocessPopplerRunner`
- `FakePopplerRunner` for tests
- `run_pdfinfo(input_pdf: Path) -> PdfInfo`
- `run_pdftoppm(input_pdf: Path, output_dir: Path, dpi: int) -> list[Path]`
- `run_pdftotext_bbox(input_pdf: Path, output_xhtml: Path) -> Path`

Use `subprocess.run(..., check=True, capture_output=True, text=True)` and return typed errors with stderr included.

Configuration rules:

- `PDF_TRANSLATOR_POPPLER_ROOT` points to the Poppler bundle root.
- The default bundle root is `src/pdf_translator/vendor/poppler`.
- The platform key for the first build is `macos-arm64`.
- The final binary paths are `<root>/<platform-key>/bin/pdfinfo`, `<root>/<platform-key>/bin/pdftoppm`, and `<root>/<platform-key>/bin/pdftotext`.
- Add a startup validation helper that checks all three files exist and are executable.
- Document Poppler binary provenance and license obligations in `apps/pdf-translator/THIRD_PARTY_NOTICES.md`.

**Step 4: Run unit tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_poppler.py -v
```

Expected: PASS.

**Step 5: Add optional integration test**

Only run integration tests when `PDF_TRANSLATOR_POPPLER_ROOT` is set, so CI and local development do not fail before binaries are copied in.

```bash
PDF_TRANSLATOR_POPPLER_ROOT=/absolute/path/to/vendor/poppler pytest tests/test_poppler_integration.py -v
```

**Step 6: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/config.py apps/pdf-translator/backend/src/pdf_translator/poppler.py apps/pdf-translator/backend/tests apps/pdf-translator/THIRD_PARTY_NOTICES.md
git commit -m "feat: add poppler binary adapter"
```

## Task 3: Parse `pdftotext -bbox-layout` Output

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/bbox_parser.py`
- Modify: `apps/pdf-translator/backend/src/pdf_translator/models.py`
- Create: `apps/pdf-translator/backend/tests/fixtures/simple_bbox.html`
- Create: `apps/pdf-translator/backend/tests/fixtures/actual_poppler_bbox.html`
- Create: `apps/pdf-translator/backend/tests/test_bbox_parser.py`

**Step 1: Add a fixture with one page, one block, one line, and several words**

Add two fixtures:

- `simple_bbox.html` for small focused parser tests.
- `actual_poppler_bbox.html` captured from a real `pdftotext -bbox-layout sample.pdf actual_poppler_bbox.html` command, so parser behavior is anchored to Poppler's real XHTML shape.

The small fixture should resemble Poppler XHTML:

```html
<doc>
  <page width="595.276" height="841.89">
    <block xMin="72" yMin="96" xMax="520" yMax="140">
      <line xMin="72" yMin="96" xMax="520" yMax="112">
        <word xMin="72" yMin="96" xMax="110" yMax="112">Hello</word>
        <word xMin="116" yMin="96" xMax="150" yMax="112">world</word>
      </line>
    </block>
  </page>
</doc>
```

**Step 2: Write parser tests**

```python
from pathlib import Path

from pdf_translator.bbox_parser import parse_bbox_layout


def test_parse_bbox_layout_reads_pages_blocks_lines_and_words():
    pages = parse_bbox_layout(Path("tests/fixtures/simple_bbox.html"))

    assert len(pages) == 1
    assert pages[0].width == 595.276
    assert pages[0].height == 841.89
    assert pages[0].blocks[0].text == "Hello world"


def test_parse_actual_poppler_bbox_fixture():
    pages = parse_bbox_layout(Path("tests/fixtures/actual_poppler_bbox.html"))

    assert pages
    assert pages[0].width > 0
    assert pages[0].height > 0
    assert any(block.text for block in pages[0].blocks)
```

**Step 3: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_bbox_parser.py -v
```

Expected: FAIL because the parser does not exist.

**Step 4: Implement parser and coordinate models**

Add models:

- `Box(x_min, y_min, x_max, y_max)`
- `PdfWord`
- `PdfLine`
- `PdfBlock`
- `PdfPageLayout`

Keep Poppler's top-left-origin coordinates in the parsed layout. Convert to PDF bottom-left coordinates only inside the renderer.

**Step 5: Run parser tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_bbox_parser.py -v
```

Expected: PASS.

**Step 6: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/bbox_parser.py apps/pdf-translator/backend/src/pdf_translator/models.py apps/pdf-translator/backend/tests
git commit -m "feat: parse poppler bbox layout"
```

## Task 4: Classify Body, Vertical, and Note Blocks

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/block_classifier.py`
- Modify: `apps/pdf-translator/backend/src/pdf_translator/models.py`
- Create: `apps/pdf-translator/backend/tests/test_block_classifier.py`

**Step 1: Write classification tests**

```python
from pdf_translator.block_classifier import classify_block
from pdf_translator.models import BlockKind, Box, PdfBlock


def test_wide_block_is_horizontal_body_text():
    block = PdfBlock(id="p1-b1", box=Box(72, 96, 520, 160), lines=[], text="Long body paragraph")
    assert classify_block(block, page_width=595, page_height=842).kind == BlockKind.BODY_HORIZONTAL


def test_tall_narrow_margin_block_is_note_or_vertical_text():
    block = PdfBlock(id="p1-b2", box=Box(520, 120, 560, 500), lines=[], text="縦書き注釈")
    assert classify_block(block, page_width=595, page_height=842).kind == BlockKind.NOTE_OR_VERTICAL
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_block_classifier.py -v
```

Expected: FAIL because the classifier does not exist.

**Step 3: Implement first-pass heuristics**

Use conservative rules:

- Ignore empty blocks and page numbers.
- Treat wide blocks as horizontal body text.
- Treat tall narrow blocks as vertical or note text.
- Treat blocks near right, left, bottom, or top margins with small text area as notes.
- Keep an `UNKNOWN` class and send it to DOCX/Markdown fallback instead of dropping content.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_block_classifier.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/block_classifier.py apps/pdf-translator/backend/tests/test_block_classifier.py
git commit -m "feat: classify pdf text blocks"
```

## Task 5: Add Translation Interface and Fake Translator

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/translator.py`
- Create: `apps/pdf-translator/backend/tests/test_translator.py`

**Step 1: Write tests against a fake translator**

```python
from pdf_translator.translator import FakeTranslator, TranslationRequest


def test_fake_translator_preserves_block_ids():
    translator = FakeTranslator()
    result = translator.translate([
        TranslationRequest(block_id="p1-b1", text="Hello world", source_language="en", target_language="ko")
    ])

    assert result[0].block_id == "p1-b1"
    assert result[0].translated_text
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_translator.py -v
```

Expected: FAIL because translation types do not exist.

**Step 3: Implement translator abstraction**

Create:

- `TranslationRequest`
- `TranslationResult`
- `Translator` protocol
- `FakeTranslator`

Translation requests must preserve block IDs and return Korean only. Fake translation exists only for unit tests and pipeline tests that do not call the network.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_translator.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/translator.py apps/pdf-translator/backend/tests/test_translator.py
git commit -m "feat: add translation abstraction"
```

## Task 6: Add Configured Production Translation Provider

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/providers/__init__.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/providers/external_json.py`
- Modify: `apps/pdf-translator/backend/src/pdf_translator/config.py`
- Create: `apps/pdf-translator/backend/tests/test_external_translator.py`

**Step 1: Write tests with mocked HTTP responses**

```python
import httpx

from pdf_translator.providers.external_json import ExternalJsonTranslator
from pdf_translator.translator import TranslationRequest


def test_external_json_translator_preserves_ids_and_returns_korean(httpx_mock):
    httpx_mock.add_response(json={
        "translations": [
            {"block_id": "p1-b1", "translated_text": "한국어 번역입니다."}
        ]
    })
    translator = ExternalJsonTranslator(
        endpoint="https://translator.example.test/translate",
        api_key="test-key",
        client=httpx.Client(),
    )

    result = translator.translate([
        TranslationRequest(block_id="p1-b1", text="Hello world", source_language="en", target_language="ko")
    ])

    assert result[0].block_id == "p1-b1"
    assert result[0].translated_text == "한국어 번역입니다."
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_external_translator.py -v
```

Expected: FAIL because the provider does not exist.

**Step 3: Implement provider contract**

Implement `ExternalJsonTranslator` as the first production-capable provider:

- Read `PDF_TRANSLATOR_TRANSLATE_ENDPOINT` and `PDF_TRANSLATOR_API_KEY` from config.
- Send batches of `TranslationRequest` objects as JSON.
- Require a response shaped like `{"translations": [{"block_id": "...", "translated_text": "..."}]}`.
- Validate every returned `block_id` exists in the request.
- Reject empty Korean translations.
- Retry one time on transient HTTP failures.
- Raise a typed `TranslationProviderError` with enough context for the UI warnings panel.

Provider-specific adapters such as OpenAI, DeepL, or Papago can wrap this contract later. When implementing a provider-specific adapter, check that provider's official documentation before coding API calls.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_external_translator.py tests/test_translator.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/providers apps/pdf-translator/backend/src/pdf_translator/config.py apps/pdf-translator/backend/tests/test_external_translator.py
git commit -m "feat: add configured translation provider"
```

## Task 7: Build Korean Layout Engine

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/layout.py`
- Modify: `apps/pdf-translator/backend/src/pdf_translator/models.py`
- Create: `apps/pdf-translator/backend/tests/test_layout.py`

**Step 1: Write tests for wrapping and overflow**

```python
from pdf_translator.layout import fit_text_to_box
from pdf_translator.models import Box


def test_fit_text_to_box_wraps_korean_text():
    result = fit_text_to_box("한국어 번역문을 여러 줄로 배치합니다.", Box(72, 96, 220, 150), max_font_size=11)

    assert result.font_size <= 11
    assert len(result.lines) >= 1
    assert not result.overflowed
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_layout.py -v
```

Expected: FAIL because layout code does not exist.

**Step 3: Implement layout primitives**

Implement:

- Korean text wrapping by measured string width.
- Font-size reduction down to a configured minimum.
- Body block layout in original source box.
- Note-zone layout in bottom or right areas.
- Overflow reporting.
- `notes_page` policy for blocks that cannot fit on the original page.
- `expand_page` policy for an alternate output mode.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_layout.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/layout.py apps/pdf-translator/backend/tests/test_layout.py
git commit -m "feat: add korean pdf layout engine"
```

## Task 8: Generate Selectable Korean PDF

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/pdf_renderer.py`
- Modify: `apps/pdf-translator/backend/src/pdf_translator/models.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/assets/fonts/NotoSansKR-Regular.ttf`
- Create: `apps/pdf-translator/backend/tests/fixtures/fonts/NotoSansKR-Regular.ttf`
- Create: `apps/pdf-translator/backend/tests/test_pdf_renderer.py`

**Step 1: Write renderer test**

```python
from pathlib import Path

from PIL import Image
from pypdf import PdfReader

from pdf_translator.models import BlockKind, Box, PdfPageLayout, TranslatedBlock
from pdf_translator.pdf_renderer import render_translated_pdf


def test_rendered_pdf_contains_selectable_korean_text(tmp_path):
    output = tmp_path / "translated.pdf"
    background = tmp_path / "page-1.png"
    Image.new("RGB", (595, 842), "white").save(background)

    render_translated_pdf(
        pages=[PdfPageLayout(page_number=1, width=595, height=842, blocks=[])],
        page_images=[background],
        translated_blocks=[
            TranslatedBlock(
                block_id="p1-b1",
                page_number=1,
                kind=BlockKind.BODY_HORIZONTAL,
                source_box=Box(72, 96, 300, 150),
                translated_text="한국어 번역입니다.",
            )
        ],
        output_pdf=output,
        korean_font_path=Path("tests/fixtures/fonts/NotoSansKR-Regular.ttf"),
    )

    text = "\n".join(page.extract_text() or "" for page in PdfReader(output).pages)
    assert "한국어 번역입니다." in text
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_pdf_renderer.py -v
```

Expected: FAIL because renderer does not exist.

**Step 3: Implement PDF renderer**

Use ReportLab:

- create a page with the original page size,
- draw the page image as a full-page background,
- convert Poppler top-left coordinates to PDF bottom-left coordinates,
- draw cover rectangles over source text with small configurable padding so glyph edges are covered,
- draw Korean body text as real text,
- draw note markers near source note/vertical blocks,
- draw note translations in bottom or right note zones,
- add extra notes pages when `notes_page` overflow policy requires it,
- embed a Korean font.

**Step 4: Verify selectable text**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_pdf_renderer.py -v
```

Expected: PASS and `pypdf` can extract Korean text from the generated PDF.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/pdf_renderer.py apps/pdf-translator/backend/src/pdf_translator/models.py apps/pdf-translator/backend/src/pdf_translator/assets/fonts apps/pdf-translator/backend/tests/fixtures/fonts apps/pdf-translator/backend/tests/test_pdf_renderer.py
git commit -m "feat: render selectable korean translation pdf"
```

## Task 9: Add DOCX, TXT, and Markdown Fallbacks

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/fallback_outputs.py`
- Create: `apps/pdf-translator/backend/tests/test_fallback_outputs.py`

**Step 1: Write fallback tests**

```python
from pdf_translator.fallback_outputs import render_markdown


def test_render_markdown_includes_page_and_block_translation():
    markdown = render_markdown([
        {"page": 1, "block_id": "p1-b1", "text": "한국어 번역입니다."}
    ])

    assert "## Page 1" in markdown
    assert "한국어 번역입니다." in markdown
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_fallback_outputs.py -v
```

Expected: FAIL because fallback output code does not exist.

**Step 3: Implement fallback writers**

Generate:

- `translated.md`
- `translated.txt`
- `translated.docx`
- `manifest.json` with block IDs, source text, translated text, classification, placement status, and overflow status.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_fallback_outputs.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/fallback_outputs.py apps/pdf-translator/backend/tests/test_fallback_outputs.py
git commit -m "feat: add translation fallback outputs"
```

## Task 10: Wire End-to-End Pipeline and CLI

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/cli.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/pipeline.py`
- Create: `apps/pdf-translator/backend/tests/test_pipeline.py`

**Step 1: Write pipeline test with fake Poppler runner and fake translator**

```python
from reportlab.pdfgen import canvas

from pdf_translator.pipeline import translate_pdf
from pdf_translator.poppler import FakePopplerRunner
from pdf_translator.translator import FakeTranslator


def test_pipeline_creates_pdf_and_fallbacks(tmp_path):
    input_pdf = tmp_path / "sample.pdf"
    c = canvas.Canvas(str(input_pdf))
    c.drawString(72, 720, "Hello world")
    c.save()

    result = translate_pdf(
        input_pdf=input_pdf,
        output_dir=tmp_path / "out",
        translator=FakeTranslator(),
        poppler_runner=FakePopplerRunner.for_single_page_text("Hello world"),
    )

    assert result.pdf.exists()
    assert result.markdown.exists()
    assert result.manifest.exists()
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_pipeline.py -v
```

Expected: FAIL because pipeline does not exist.

**Step 3: Implement pipeline orchestration**

Pipeline stages:

1. create job work directory,
2. inspect PDF,
3. render page images,
4. extract bbox layout,
5. parse and classify blocks,
6. translate blocks,
7. plan layout,
8. render translated PDF,
9. render fallbacks,
10. return output paths and warnings.

Do not add a `use_fake_poppler` branch to production code. Define a `PopplerRunner` protocol and pass a fake runner in tests.

**Step 4: Add CLI**

Example:

```bash
pdf-translator translate input.pdf --out ./out --source auto --target ko --overflow notes_page
```

**Step 5: Run unit tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_pipeline.py -v
```

Expected: PASS.

**Step 6: Run manual integration test**

Run:

```bash
cd apps/pdf-translator/backend
PDF_TRANSLATOR_POPPLER_ROOT=/absolute/path/to/vendor/poppler \
pdf-translator translate /absolute/path/to/sample.pdf --out /tmp/pdf-translator-sample --target ko
```

Expected:

- `/tmp/pdf-translator-sample/translated.pdf` opens visually.
- Korean text can be selected and copied from the PDF.
- `/tmp/pdf-translator-sample/translated.docx`, `.txt`, `.md`, and `manifest.json` exist.

**Step 7: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/cli.py apps/pdf-translator/backend/src/pdf_translator/pipeline.py apps/pdf-translator/backend/tests/test_pipeline.py
git commit -m "feat: wire pdf translation pipeline"
```

## Task 11: Add Local API Server

**Files:**
- Create: `apps/pdf-translator/backend/src/pdf_translator/api.py`
- Create: `apps/pdf-translator/backend/src/pdf_translator/job_store.py`
- Create: `apps/pdf-translator/backend/tests/test_api.py`

**Step 1: Write API tests**

```python
from fastapi.testclient import TestClient

from pdf_translator.api import app


def test_health_endpoint():
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["ok"] is True
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_api.py -v
```

Expected: FAIL because API app does not exist.

**Step 3: Implement API endpoints**

Endpoints:

- `GET /health`
- `POST /jobs` with PDF upload and settings
- `GET /jobs/{job_id}` for status, warnings, and progress
- `GET /jobs/{job_id}/download/pdf`
- `GET /jobs/{job_id}/download/docx`
- `GET /jobs/{job_id}/download/txt`
- `GET /jobs/{job_id}/download/md`

Run translation jobs in a background task. Store job metadata under a local app data directory.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/backend
pytest tests/test_api.py -v
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/backend/src/pdf_translator/api.py apps/pdf-translator/backend/src/pdf_translator/job_store.py apps/pdf-translator/backend/tests/test_api.py
git commit -m "feat: add local pdf translator api"
```

## Task 12: Create React Frontend

**Files:**
- Create: `apps/pdf-translator/frontend/package.json`
- Create: `apps/pdf-translator/frontend/vitest.config.ts`
- Create: `apps/pdf-translator/frontend/index.html`
- Create: `apps/pdf-translator/frontend/src/App.tsx`
- Create: `apps/pdf-translator/frontend/src/api.ts`
- Create: `apps/pdf-translator/frontend/src/test/setup.ts`
- Create: `apps/pdf-translator/frontend/src/components/FileDropzone.tsx`
- Create: `apps/pdf-translator/frontend/src/components/JobProgress.tsx`
- Create: `apps/pdf-translator/frontend/src/components/OutputDownloads.tsx`
- Create: `apps/pdf-translator/frontend/src/styles.css`

**Step 1: Write frontend smoke test**

```tsx
// apps/pdf-translator/frontend/src/App.test.tsx
import { render, screen } from "@testing-library/react";
import App from "./App";

test("renders pdf translator upload surface", () => {
  render(<App />);
  expect(screen.getByText("PDF 번역")).toBeInTheDocument();
});
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd apps/pdf-translator/frontend
npm install
npm test -- --run
```

Expected: FAIL because the frontend does not exist yet.

**Step 3: Implement UI**

Add the minimum package setup:

```json
{
  "scripts": {
    "dev": "vite",
    "test": "vitest",
    "build": "tsc && vite build"
  },
  "dependencies": {
    "@vitejs/plugin-react": "latest",
    "vite": "latest",
    "react": "latest",
    "react-dom": "latest"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "latest",
    "@testing-library/react": "latest",
    "@types/react": "latest",
    "@types/react-dom": "latest",
    "jsdom": "latest",
    "typescript": "latest",
    "vitest": "latest"
  }
}
```

After `npm install`, commit the generated lockfile so subsequent implementation sessions use pinned versions.

Add Vitest browser-like test setup:

```ts
// apps/pdf-translator/frontend/vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: "./src/test/setup.ts"
  }
});
```

```ts
// apps/pdf-translator/frontend/src/test/setup.ts
import "@testing-library/jest-dom/vitest";
```

The first screen should be the actual tool, not a landing page:

- PDF file picker/dropzone.
- Source language control: `자동`, `일본어`, `영어`.
- Target language fixed to `한국어`.
- Cover style control: white, translucent.
- Note overflow policy: `별도 주석 페이지`, `페이지 확장`.
- Start button.
- Progress timeline.
- Warnings panel for blocks that could not be placed cleanly.
- Download buttons for PDF, DOCX, TXT, Markdown.

**Step 4: Run tests**

Run:

```bash
cd apps/pdf-translator/frontend
npm install
npm test -- --run
```

Expected: PASS.

**Step 5: Commit**

```bash
git add apps/pdf-translator/frontend
git commit -m "feat: add pdf translator frontend"
```

## Task 13: Manual QA and Packaging Notes

**Files:**
- Modify: `apps/pdf-translator/backend/README.md`
- Create: `apps/pdf-translator/QA.md`
- Modify: `apps/pdf-translator/THIRD_PARTY_NOTICES.md`

**Step 1: Add QA checklist**

Cover these samples:

- English text-only PDF.
- Japanese horizontal novel/document PDF.
- Japanese mixed horizontal and vertical note PDF.
- PDF with mid-page images.
- PDF with long notes that require a notes page.
- PDF with long notes using expanded-page mode.

**Step 2: Verify selectable Korean**

For each output PDF:

1. Open the file in Preview or a browser PDF viewer.
2. Drag-select Korean text.
3. Copy and paste into a text editor.
4. Confirm copied text is Korean, not an image.
5. Run text extraction:

```bash
python - <<'PY'
from pathlib import Path
from pypdf import PdfReader

pdf = Path("/tmp/pdf-translator-sample/translated.pdf")
text = "\n".join(page.extract_text() or "" for page in PdfReader(pdf).pages)
assert any("\uac00" <= ch <= "\ud7a3" for ch in text)
print("Korean text layer detected")
PY
```

**Step 3: Document macOS limitation**

Document that the MVP is macOS-first because bundled Poppler binaries are macOS-specific. Add future packaging notes for:

- `macos-arm64`
- `macos-x64`
- `windows-x64`
- `linux-x64`

Also document:

- exact Poppler binary source and version,
- license obligations for Poppler and bundled font files,
- binary architecture verification with `file path/to/pdftotext`,
- executable-bit verification for `pdfinfo`, `pdftoppm`, and `pdftotext`,
- macOS quarantine/notarization considerations for distributed `.app` or packaged binaries.

**Step 4: Commit**

```bash
git add apps/pdf-translator/backend/README.md apps/pdf-translator/QA.md apps/pdf-translator/THIRD_PARTY_NOTICES.md
git commit -m "docs: add pdf translator qa checklist"
```

## Risks and Mitigations

- **Korean text does not fit in source boxes:** reduce font size, wrap lines, move note-like content to bottom/right zones, and record overflow in `manifest.json`.
- **Vertical Japanese detection is imperfect:** classify conservatively and expose warnings in the UI.
- **Copied PDF text order is odd:** draw Korean text in human reading order and validate with text extraction.
- **Some PDFs have strange embedded text order:** use Poppler bbox coordinates as the primary layout source and keep DOCX/Markdown fallbacks.
- **Scanned PDFs are unsupported in MVP:** detect pages with little/no extracted text and show a clear "OCR required" warning.
- **Bundled binaries are platform-specific:** isolate Poppler path resolution behind `PopplerPaths` and add platform packages later.
- **Bundled binary/font licensing can block distribution:** record source, version, and license obligations before packaging.
- **Translation API returns malformed data:** require stable block IDs in JSON, validate all IDs, retry once, and fall back to untranslated block warnings.

## Definition of Done

- A user can upload a selectable-text Japanese or English PDF.
- A configured production translation provider can translate Japanese or English blocks into Korean without using `FakeTranslator`.
- The app returns a Korean translated PDF with the original visual page background.
- Korean body text is selectable and copyable.
- Source text regions are covered with white or translucent boxes.
- Vertical or note-like source blocks are moved to Korean-friendly bottom/right note areas.
- Overflow notes are handled by notes-page or expanded-page mode.
- DOCX, TXT, Markdown, and manifest fallback outputs are generated.
- The app documents that the first build is macOS-first due to bundled Poppler binaries.
- Unit tests pass for parsing, classification, translation providers, layout, rendering, fallback outputs, pipeline, and API.
- At least three manual sample PDFs have been verified.
