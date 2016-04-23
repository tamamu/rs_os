#![feature(lang_items)]
#![feature(const_fn)]
#![feature(unique)]
#![no_std]

extern crate rlibc;
extern crate spin;

#[macro_use]
mod vga_buffer;

#[no_mangle]
pub extern fn rust_main() {
    vga_buffer::clear_screen();
    println!("Hello World{}", "!");
    println!("\nThis is my first OS implemented in Rust.");
    println!("\n\nWe can print some message in this text buffer.");
    println!("\n\n");

    let x = 30;
    let y = 15;
    println!("{} + {} = {}", x, y, x+y);
    println!("{} - {} = {}", x, y, x-y);
    println!("{} * {} = {}", x, y, x*y);
    println!("{} / {} = {}", x, y, x/y);

    println!("\n\n\n");
    println!("Powered by @p_tefu");
    loop{}
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] extern fn panic_fmt() -> ! {loop{}}
