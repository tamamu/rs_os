#![feature(lang_items)]
#![feature(const_fn)]
#![feature(unique)]
#![no_std]

extern crate rlibc;
extern crate spin;
extern crate multiboot2;

#[macro_use]
mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_main(multiboot_information_address: usize) {
    vga_buffer::clear_screen();
    println!("Hello World{}", "!");
    println!("\nThis is my first OS implemented in Rust.");
    println!("\n\nWe can print some message in this text buffer.");
    println!("\n\n");

    let x = 30;
    let y = 15;
    println!("{} + {} = {}", x, y, x + y);
    println!("{} - {} = {}", x, y, x - y);
    println!("{} * {} = {}", x, y, x * y);
    println!("{} / {} = {}", x, y, x / y);

    println!("\n\n\n");
    println!("Powered by @p_tefu");

    let boot_info = unsafe { multiboot2::load(multiboot_information_address) };
    let memory_map_tag = boot_info.memory_map_tag()
                                  .expect("Memory map tag required");

    println!("memory areas:");
    for area in memory_map_tag.memory_areas() {
        println!("  start: 0x{:x}, length: 0x{:x}",
                 area.base_addr,
                 area.length);
    }

    let elf_sections_tag = boot_info.elf_sections_tag()
                                    .expect("Elf-sections tag required");

    println!("kernel sections:");
    for section in elf_sections_tag.sections() {
        println!("  addr: 0x{:x}, size: 0x{:x}, flags: 0x{:x}",
                 section.addr,
                 section.size,
                 section.flags);
    }

    let kernel_start = elf_sections_tag.sections()
                                       .map(|s| s.addr)
                                       .min()
                                       .unwrap();
    let kernel_end = elf_sections_tag.sections()
                                     .map(|s| s.addr + s.size)
                                     .max()
                                     .unwrap();

    let multiboot_start = multiboot_information_address;
    let multiboot_end = multiboot_start + (boot_info.total_size as usize);

    loop {}
}

#[lang = "eh_personality"]
extern "C" fn eh_personality() {}
#[lang = "panic_fmt"]
extern "C" fn panic_fmt(fmt: core::fmt::Arguments, file: &str, line: u32) -> ! {
    println!("\n\nPANIC in {} at line {}:", file, line);
    println!("    {}", fmt);
    loop {}
}
