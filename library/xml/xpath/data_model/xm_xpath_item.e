indexing

	description:

		"XPath item - a member of a sequence"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2003, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class XM_XPATH_ITEM

inherit

	XM_XPATH_TYPE

feature -- Access

	string_value: STRING is
			--Value of the item as a string
		deferred
		ensure
			string_value_not_void: Result /= Void
		end

	type: INTEGER is
			-- Type;
			-- The data model requires zero or one xs:QNames.
			-- To convert, call type_name (Result) if Result > 0
		deferred
		ensure
			Result > 0 implies is_valid_type (Result)
		end
	
	typed_value: XM_XPATH_VALUE is
			-- Typed value
		deferred
		ensure
			typed_value_not_void: Result /= Void
		end
	
end
	
