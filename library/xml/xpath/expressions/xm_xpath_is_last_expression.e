indexing

	description:

		"XPath is-last Expressions"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_IS_LAST_EXPRESSION

inherit

	XM_XPATH_COMPUTED_EXPRESSION
		redefine
			evaluate_item, compute_intrinsic_dependencies
		end

creation

	make

feature {NONE} -- Initialization

	make (a_condition: BOOLEAN) is
			-- Set condition.
		do
			condition := a_condition
			compute_static_properties
		ensure
			condition_set: condition = a_condition
		end

feature -- Access
	
	item_type: INTEGER is
			--Determine the data type of the expression, if possible
		do
			Result := Boolean_type
		end

	condition: BOOLEAN
			-- Is position() eq last()?

feature -- Status setting

	
	compute_intrinsic_dependencies is
			-- Determine the intrinsic dependencies of an expression.
		do
			create intrinsic_dependencies.make (1, 6)
			-- Now all are `False', but we want depends_upon_last and depends_upon_position so:
			intrinsic_dependencies.put (True, 3)
			intrinsic_dependencies.put (True, 4)
			are_intrinsic_dependencies_computed := True
		end

feature -- Status report

	display (a_level: INTEGER; a_pool: XM_XPATH_NAME_POOL) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indent (a_level), "isLast()")
			std.error.put_string (a_string)
			std.error.put_new_line
			end

feature -- Optimization

	analyze (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Perform static analysis of `Current' and its subexpressions
		do
			set_analyzed
		end

feature -- Evaluation
	
		evaluate_item (a_context: XM_XPATH_CONTEXT) is
			-- Evaluate `Current' as a single item
		do
			todo ("evaluate-item", False)
			-- TODO
		end

feature {NONE} -- Implementation
	
	compute_cardinality is
			-- Compute cardinality.
		do
			set_cardinality_exactly_one
		end
	
end
