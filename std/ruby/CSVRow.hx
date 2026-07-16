package ruby;

/**
	One header-free row in Ruby's CSV default parsing contract.

	An unquoted empty field becomes `null`, while a quoted empty field remains an
	empty `String`. Keeping that distinction in the element type prevents CSV data
	from silently widening into arbitrary Ruby objects.
**/
typedef CSVRow = Array<Null<String>>;
