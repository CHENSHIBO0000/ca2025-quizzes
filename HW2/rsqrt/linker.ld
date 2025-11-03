OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY { RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 16M }

SECTIONS {
  . = ORIGIN(RAM);

  .text : ALIGN(4) {
    KEEP(*(.text._start))        /* 一定要保留入口 */
    KEEP(*(.init))
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > RAM

  .data : ALIGN(4) {
    *(.sdata .sdata.*)
    *(.data .data.*)
  } > RAM

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start__ = .;
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    __bss_end__ = .;
  } > RAM

  /* 堆疊放 RAM 末端（向下長） */
  . = ORIGIN(RAM) + LENGTH(RAM);
  . = ALIGN(16);
  __stack_top = .;
}
