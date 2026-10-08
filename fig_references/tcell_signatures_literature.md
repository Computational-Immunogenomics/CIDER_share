# T-cell RNA signatures for CIDER validation — status and verification log

Reference list for the RNA-based gene-set validation of the CIDER T-cell
Score. Tracks what's implemented in `0_prepare/2_rna.ipynb` and used in
`1_figures/21_tcell_geneset_panel.ipynb` (the 6-gene-set figure, grouped
into Infiltration / Effector / Exhausted -- Panel A a Pearson-r bar plot,
Panel B a Responder-vs-Non-Responder boxplot of CIDER + all 6 gene sets)
and
`1_figures/19_dna_vs_rna_response.ipynb` (the earlier DNA-vs-RNA scatter
figure, which uses a subset of these), versus what was considered but not
implemented (or implemented and later removed), and why.

**Verification discipline:** every implemented panel below has a gene list
traceable to a primary source — the original paper's own reproducible
definition (simple panels, consistently reported across many papers) —
**with one exception**: the T-cell-inflamed GEP (Ayers et al. 2017, below),
included per explicit direction despite failing this bar; see its own row
for the caveat. Two other well-known panels (Danaher et al. 2017, Bindea et
al. 2013) remain explicitly **not implemented** because their exact gene
membership could not be confirmed from a primary source — see the "Not
implemented" section below for the specific access problems encountered, so
a future attempt doesn't repeat the same dead ends.

## Implemented

| Category | Signature | Genes | Column | Source |
|---|---|---|---|---|
| Infiltration | Primary T-cell signature | CD3D, CD3E, CD3G | `tcell_tpm` | Braun, D.A. et al. "Progressive immune dysfunction with advancing disease stage in renal cell carcinoma." *Cancer Cell* 39(5):632-648.e8 (2021). PMID 33711273 |
| Infiltration | T-cell signature (HCL) | CD3D, CD3E, CD3G, CD2, TRAC | `rna_tcell_hcl_score` | Han, X., Zhou, Z., Fei, L. et al. "Construction of a human cell landscape at single-cell level." *Nature* 581, 303–309 (2020) |
| Effector | CD8 Effector (tGE8) | CD8A, GZMA, GZMB, IFNG, CXCL9, CXCL10, PRF1, TBX21 | `rna_teff_score` | Mariathasan et al. 2018 *Nature*; Rosenberg et al. 2016 *Lancet* (IMvigor210) |
| Effector | T-cell-inflamed GEP (Ayers GEPS) | PSMB10, HLA-DQA1, HLA-DRB1, CMKLR1, HLA-E, NKG7, CD8A, CCL5, CXCL9, CD27, CXCR6, IDO1, STAT1, CD274, CD276, LAG3, PDCD1LG2, TIGIT | `rna_ayers_geps_score` | Ayers et al. 2017, *J Clin Invest* 127(8):2930-2940 (PMID 28650338) — **not primary-source-verified** (see caveat below); category assigned as "Effector" as a pragmatic choice (the paper also contains antigen-presentation and checkpoint genes, so it doesn't map cleanly onto any one of this project's three categories) |
| Exhausted | Checkpoint/exhaustion panel | PDCD1 (PD-1), CTLA4, LAG3, HAVCR2 (TIM-3), TIGIT | `rna_exhaustion_score` | Canonical co-inhibitory-receptor panel, reproduced consistently across the T-cell exhaustion literature (e.g. Thommen et al. 2018 *Nat Med* 24:994-1004; Tirosh et al. 2016 *Science* 352:189-196) — not one paper's proprietary list, which is why it carries materially lower verification risk than Danaher/Bindea below despite having no single landmark citation |
| Exhausted | PD-L1 (CD274) | CD274 | `rna_pdl1_score` | Single-gene transcript-level proxy for the IHC-based PD-L1 Tumor Proportion Score/Combined Positive Score. Used both as a comparator in `19_dna_vs_rna_response.ipynb` and, now, as an Exhausted-category gene set in `21_tcell_geneset_panel.ipynb` — grouped under Exhausted (PD-L1/PD-1 axis) rather than Infiltration/Effector, despite being expressed on tumor/myeloid cells rather than T cells themselves |

**T-cell-inflamed GEP verification caveat:** this is the one panel in the
table above that does NOT meet this file's stated verification discipline.
Ayers et al. 2017's own supplementary table renders as an image (not
extractable text) in every fetch attempted, in two separate sessions. The
18-gene list used here is a secondary-source reconstruction: two
independent web searches (in different sessions) converged on the identical
18 genes, and the list matches the related Danaher et al. 2018 TIS
re-description already noted below -- but none of that is the same as
confirming it against Ayers et al. 2017's own table directly. An attempt to
pull the gene list as plain data from the IOBR R package (which bundles a
`TIS`/`Ayers`-style signature in its `signature_collection` dataset,
following this file's own "Suggested use if revisited" note below) also
failed: the data is stored in a binary `.rda` file, and GitHub's raw/API
endpoints for inspecting it returned empty in the sandbox used. Included in
`2_rna.ipynb` / `21_tcell_geneset_panel.ipynb` anyway per explicit user
direction, with this caveat surfaced in-line at every point of use (panel
definition comment, `3_meta.ipynb` comment, `GENE_SET_INFO` label asterisk,
figure caption) rather than only here.

**Aggregation note:** every panel above uses `compute_panel()`'s default
arithmetic mean of raw AdjTPM. (CYT, which used a geometric mean, has since
been removed -- see "Removed" below.)

## Removed

| Signature | Source | Status |
|---|---|---|
| MCP-counter T cells / CD8 T cells / Cytotoxic lymphocytes | Becht et al. 2016, *Genome Biology* 17:218 — gene lists verified via `github.com/ebecht/MCPcounter`, `Signatures/genes.txt` (`rna_tcell_mcp_score`, `rna_cd8_mcp_score`, `rna_cytotoxic_mcp_score`) | Implemented, then removed from `2_rna.ipynb` / `3_meta.ipynb` / `21_tcell_geneset_panel.ipynb` per explicit direction. The verified gene lists above are kept here for reference if ever reinstated — the primary-source verification was sound; the panels were pulled for a different, unrecorded reason. |
| Cytolytic activity (CYT) | Rooney et al. 2015, *Cell* 160(1-2):48-61 — GZMA, PRF1, **geometric** mean (`exp(rowMeans(log(x)))`, not `compute_panel()`'s arithmetic-mean default); `rna_cyt_score` | Implemented, then removed from `2_rna.ipynb` / `3_meta.ipynb` / `21_tcell_geneset_panel.ipynb` per explicit direction, as part of trimming the gene-set panel down to exactly 5 signatures. |

## Not implemented

| Signature | Source | Why not implemented |
|---|---|---|
| Danaher "T cells" / "CD8 T cells" / "Cytotoxic cells" / "Exhausted CD8" | Danaher et al. 2017, *J Immunother Cancer* 5:18 (PMC5319024) | NCBI PMC blocked the supplementary-table fetch behind a CAPTCHA (tried in two separate sessions); a related JITC table page returned only a fragment, not the full panel. Secondhand reconstructions attempted via web search were inconsistent across sources. |
| Bindea "T cells" / "CD8 T cells" | Bindea et al. 2013, *Immunity* 39(4):782-795 (PMID 24138885) | The paper's own supplementary table could not be fetched; a web-search reconstruction returned a 26-gene list (ADRM1, AHSA1, C1GALT1C1, ...) that does not read as a plausible CD8 T-cell marker panel (includes genes with no known T-cell specificity), indicating the secondary source conflated Bindea's signature with something else. An attempt to fetch the gene set from the `immunedeconv` R package's GitHub repo (which bundles Bindea's signatures) timed out. |
| Treg marker panel (FOXP3, IL2RA, CTLA4) | Canonical Treg markers | Verifiable, but out of scope for this figure — the supplemental gene-set panel (`21_tcell_geneset_panel.ipynb`) was scoped to exactly three categories (Infiltration / Effector / Exhausted) per direction; Treg is a fourth, distinct functional axis. |
| Naive T-cell marker panel (CCR7, SELL, TCF7, LEF1) | Canonical naive/stem-like markers | Same reason as Treg above — out of scope for the three-category figure, not a verification problem. |

## Suggested use if revisited

If Danaher or Bindea panels are needed in the future, the most promising
unexplored path is an R/Bioconductor package that bundles the gene lists as
plain data rather than reproducing the original paper's PDF table — e.g.
`immunedeconv`, `ConsensusTME`, or `IOBR` on GitHub (raw `.R`/`.rda`/`.csv`
files under `data-raw/` or `data/`, which load as plain text rather than
being blocked like the PMC/JCI supplementary files were). One such fetch
(`immunedeconv`'s `data-raw/bindea.R`) was attempted here and timed out
rather than failing outright — worth retrying before assuming GitHub-hosted
sources are unreachable in general.

The same path was retried for Ayers/TIS specifically (IOBR's
`signature_collection` dataset) when that panel was added — it did not pan
out (the data is in a binary `.rda`, and GitHub's raw/API endpoints
returned empty), which is why that panel was ultimately added as a flagged
secondary-source reconstruction instead of a verified primary-source panel.
If revisiting, the one unexplored option left is loading the actual `.rda`
with an R session (or Python's `pyreadr`, if available) rather than trying
to inspect it over HTTP.

Any newly verified panel should be added to `2_rna.ipynb` following the
existing `compute_panel()` pattern (mean raw AdjTPM, same scale as every
other panel — or a custom `agg_fn` if the original paper defines a
non-arithmetic aggregation, as CYT does), propagated through
`3_meta.ipynb`'s `transmute()` allowlist, and added as a new row to
`21_tcell_geneset_panel.ipynb`'s `GENE_SET_INFO` table.
