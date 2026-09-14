# 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices

---

## Overview

The repository contains the necessary files and collateral to create and build
the 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices.

The product of this repository is generated using a software and
hardware flow, and it is listed in the following table:

| Product | Type | Description |
|----|----|----|
| `.sof` | SRAM Object File | FPGA bitstream to be loaded over JTAG |

---

## Project Details

- **Title**: 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices
- **URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/tree/rel/26.1.1
- **Category**: Video/Vision
- **Source**: GitHub
- **Family**: Agilex 5
- **Quartus Version**: 26.1.1
- **Development Kit**: Agilex™ 5 FPGA and SoC E-Series 065B Modular Development Kit MK-A5E065BB32AEA
- **Device Part**: A5ED065BB32AE4S
- **Design Package**: agilex5e_mdk_4k_sdi_genlock_hdr_ed.zip
- **Download URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/releases/download/rel-26.1.1/agilex5e_mdk_4k_sdi_genlock_hdr_ed.zip
- **Precompiled SOF**: [golden_4k_sdi_genlock_hdr_ed.sof](https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/releases/download/rel-26.1.1/golden_4k_sdi_genlock_hdr_ed.sof)

---

## Documentation

- **Title**: 4Kp60 SDI-based Genlock HDR Video Pipeline User Guide 
- **URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/blob/rel/26.1.1/agilex5e-ed/a5e065b-mod-devkit/docs/doc-genlock-hdr.md

---

## Quick Start

1. Download the example design from the repository listed in the following table.

| Component | Location | Branch / Tag |
|-----------|----------|--------------|
| Assets release tag | [rel-26.1.1](https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/releases/tag/rel-26.1.1) | `rel-26.1.1` |

2. Extract the package.

3. Confirm that the FPGA design files are in `src/vds/`, `src/rtl/` and `src/ip/`.

4. Confirm that the software files are in `src/sw/`.

   The example design directory structure is as follows:

```text
<Example Design>/
├── sdi_genlock_hdr_ed.qpf   # Quartus project file
├── sdi_genlock_hdr_ed.qsf   # Quartus settings file
├── da_drc.dawf              # Design Assistant waiver file
├── README.md                # Repository readme
├── docs/                    # User guide for this example design
├── output_files/            # Precompiled SOF
├── script/                  # Scripts used to generate the example design
└── src/
    ├── ip/                  # .ip files
    ├── rtl/                 # RTL and SDC files
    ├── sw/                  # Bare-metal software application
    └── vds/                 # Tcl to generate the Visual Designer Studio (VDS) project
        └── test_luts/       # A collection of 3D cube files to preconfigure the 3D LUT IP
```

5. Launch the Quartus® Prime Pro Edition software.

6. Open `<Example Design>/sdi_genlock_hdr_ed.qpf`.

7. On the **Processing** menu, click **Start Compilation**.

8. Wait until compilation completes.

After a successful compilation, the Quartus® Prime software generates the programming file in the `<Example Design>/output_files/` directory:

* `sdi_genlock_hdr_ed.sof`

---

## Recompiling the Nios® V Software Application

To rebuild the Nios® V software application and merge it into the .sof, type the following commands:

```bash
cd <Example Design>/script/
quartus_sh -t post_swapp_sdi_gen.tcl
```

The script compiles the Nios® V application, merges the generated hexadecimal (HEX) ROM into the project, and generates an updated `sdi_genlock_hdr_ed.sof` that contains the latest software.

---



