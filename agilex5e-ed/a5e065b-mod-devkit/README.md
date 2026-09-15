# 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices

The 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices demonstrates three-dimensional lookup table (3D LUT)-based conversion between high dynamic range (HDR) and standard dynamic range (SDR) video. HDR-to-SDR conversion is required for interoperability between legacy and emerging formats in broadcast workflows.

## Description

The design comprises hardware and software components: The software is a bare-metal application that runs on a Nios® V soft processor. The application provides runtime control and debug menus through a JTAG UART interface. The following figure shows the interaction between the Nios® V software and the hardware in the FPGA fabric. The hardware includes one bypass path and two HDR datapaths. Each path is fully genlocked and does not use a frame buffer. The hardware also includes VVP Suite IP cores and an embedded processor subsystem. Each HDR datapath contains a 3D LUT IP core that is initialized with 3D cube files that implement a specific HDR-to-SDR conversion. A Mixer IP at the output of the pipeline combines the HDR and bypass streams with a background layer from the Test Pattern Generator (TPG) IP into a single video frame. The software can configure the Mixer IP for side-by-side display of the input video and the 3D LUT result. Processed video leaves the design through the SDI transmit interface.

## Project Details

- **Title**: 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices
- **Source**: Github
- **Family**: Agilex 5
- **Quartus Version**: 26.1.1
- **Development Kit**: Agilex™ 5 FPGA and SoC E-Series 065B Modular Development Kit MK-A5E065BB32AEA
- **Device Part**: A5ED065BB32AE4S
- **Design Package**: agilex5e_mdk_4k_sdi_genlock_hdr_ed.zip
- **Category**: Video/Vision
- **URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/tree/rel/26.1.1/agilex5e-ed/a5e065b-mod-devkit
- **download URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/releases/download/rel-26.1.1/agilex5e_mdk_4k_sdi_genlock_hdr_ed.zip

---

## Documentation

- **Title**: User Guide
- **URL**: https://github.com/altera-fpga/agilex5-ed-genlock-hdr-video/blob/rel/26.1.1/agilex5e-ed/a5e065b-mod-devkit/docs/doc-genlock-hdr.md

---

## Repository Overview

The repository contains the necessary files and collateral to create and build
the 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices.

The product of this repository is generated using a software and
hardware flow, and it is listed in the following table:

| Product | Type | Description |
|----|----|----|
| `.sof` | SRAM Object File | FPGA bitstream to be loaded over JTAG |

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



