# 4Kp60 SDI-based Genlock HDR Video Pipeline System Example Design for Agilex™ 5 Devices — Design Security Considerations

This system example design is provided as a demonstration of the IP components in a multi-channel video pipeline. The design is not intended for use in a final product or for production deployment.

Some features of the design may not meet your safety and security requirements. You must conduct a safety and security review of your final design to confirm that the design meets your product requirements. The following topics identify example areas for further consideration. This list is not exhaustive. You must perform a full security review of your system, including hardware, FPGA design, and software, according to the market requirements of the final product.

## JTAG and Serial Port Connections

The development kit hardware provides access to parts of the design through industry-standard interfaces. In this example design, these ports remain available to provide visibility into the design and to support debug.

Determine whether these access points must be available on your hardware. If you retain them, protect them according to your security requirements and policies.

## Debug Capability

This design includes multiple debug paths, including Signal Tap logic analyzer access, in-system memory editors, and debugger connections. This level of debug access may not be appropriate in the final product. Altera recommends that you remove or restrict these capabilities in a production design.

## Encrypted and Protected Video Streams

This design uses an industry-standard serial digital interface (SDI) for video input and output. Within the FPGA, the video streams are not protected against security attacks. If your security requirements include content protection, implement encryption or equivalent protection methods.

## FPGA Bitstream Encryption

This design does not use Altera FPGA bitstream encryption. You can enable bitstream encryption to protect the FPGA design content in your products. For Secure Device Manager (SDM)-based devices such as Agilex™ 5, refer to [Security Overview for SDM-Based FPGA Devices](https://docs.altera.com/r/docs/794424/current/security-overview-for-sdm-based-fpga-devices/fpga-device-security-overview).

## Secure Boot

This design does not implement a secure boot flow. The control software is a bare-metal application that runs on a Nios® V processor and is packaged in the FPGA SRAM Object File (.sof). The .sof is programmed over JTAG and is not encrypted.

In a production product, Altera recommends that you restrict debug access, enable bitstream encryption where required, and control which users can program or update the FPGA image.

## Remote Updates

This system example design does not include remote update capability. Production products often require a method to patch vulnerabilities and deploy improvements when physical access is not practical.

You can add remote update for the FPGA bitstream and embedded software, and you must provide a recovery mechanism if an update fails. You can also add remote reset or power-cycling features, depending on the application.

## Related Information

* [Security Overview for SDM-Based FPGA Devices](https://docs.altera.com/r/docs/794424/current/security-overview-for-sdm-based-fpga-devices/fpga-device-security-overview)

[Return to the Main User Guide](./doc-genlock-hdr.md#additional-information)




