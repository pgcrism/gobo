indexing

	description:

		"XPath items in error"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date:"
	revision: "$Revision: "

class XM_XPATH_INVALID_ITEM

inherit

	XM_XPATH_ITEM

creation

	make, make_from_string

feature {NONE} -- Initialization

	make (an_error: XM_XPATH_ERROR_VALUE) is
			-- Establish invariant.
		require
			error_not_void: an_error /= Void
		do
			set_last_error (an_error)
		ensure
			error_set: error_value = an_error
		end

	make_from_string (a_string: STRING; an_error_code, an_error_type: INTEGER) is
			-- Create from `a_string'.
		require
			valid_error_code: is_valid_error_code (an_error_code)
			valid_error_type: an_error_type = Static_error or an_error_type = Type_error or an_error_type = Dynamic_error
			string_not_void: a_string /= Void and then a_string.count > 0
		do
			create error_value.make_from_string (a_string, an_error_code, an_error_type)
			is_error := True
		ensure
			item_set: error_value.item /= Void and then STRING_.same_string (error_value.item.string_value, a_string)
			code_set: error_value.code = an_error_code
			type_set: error_value.type = an_error_type
		end

feature -- Access

	string_value: STRING is
			--Value of the item as a string
		do
			do_nothing -- pre-condition cannot be met
		end

	item_type: XM_XPATH_ITEM_TYPE is
			-- Type
		do
			do_nothing -- pre-condition cannot be met
		end
	
	typed_value: XM_XPATH_VALUE is
			-- Typed value
		do
			do_nothing -- pre-condition cannot be met
		end

feature -- Status report

	is_error: BOOLEAN
			-- Has item failed evaluation?
	
	error_value: XM_XPATH_ERROR_VALUE
			-- Error value


feature -- Status setting

	set_last_error (an_error_value: XM_XPATH_ERROR_VALUE) is
			-- Set `error_value'.
		do
			is_error := True
			error_value := an_error_value
		end

	set_last_error_from_string (a_message: STRING; a_code, an_error_type: INTEGER) is
			-- Set `error_value'.
		do
			is_error := True
			create error_value.make_from_string (a_message, a_code, an_error_type)
		end

invariant

	item_in_error: is_error

end
	