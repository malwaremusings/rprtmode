
SECTIONS
{
    .text 0x7c00 :
    {
	_text = .;
	*(.text*)
	*(.rodata*)
	_etext = .;
	. = 0x1fe;
	_id = .;
	*(.id*)
    } =0x00000000
}
