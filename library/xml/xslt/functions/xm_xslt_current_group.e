indexing

	description:

		"Objects that implement the XSLT current-group() function"

	library: "Gobo Eiffel XSLT Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XSLT_CURRENT_GROUP

inherit

	XM_XPATH_SYSTEM_FUNCTION
		redefine
			pre_evaluate, evaluate_item, iterator, compute_intrinsic_dependencies
		end

creation

	make

feature {NONE} -- Initialization

	make is
			-- Establish invariant
		do
			name := "current-group"
			minimum_argument_count := 0
			maximum_argument_count := 0
			create arguments.make (0)
			arguments.set_equality_tester (expression_tester)
			compute_static_properties
		end

feature -- Access

	item_type: XM_XPATH_ITEM_TYPE is
			-- Data type of the expression, where known
		do
			Result := any_item
			if Result /= Void then
				-- Bug in SE 1.0 and 1.1: Make sure that
				-- that `Result' is not optimized away.
			end
		end

feature -- Status report

	required_type (argument_number: INTEGER): XM_XPATH_SEQUENCE_TYPE is
			-- Type of argument number `argument_number'
		do
			do_nothing -- will never be called
		end

feature -- Status setting

	compute_intrinsic_dependencies is
			-- Determine the intrinsic dependencies of an expression.
		do
			set_intrinsically_depends_upon_current_group
		end

feature -- Evaluation

	iterator (a_context: XM_XPATH_CONTEXT): XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_ITEM] is
			-- Iterator over the values of a sequence
		do
			todo ("iterator", False)
		end

	evaluate_item (a_context: XM_XPATH_CONTEXT) is
			-- Evaluate `Current' as a single item
		do
			todo ("evaluate_item", False)
		end

	pre_evaluate (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Pre-evaluate `Current' at compile time.
		do
			set_replacement (Current)
		end

feature {XM_XPATH_EXPRESSION} -- Restricted

	compute_cardinality is
			-- Compute cardinality.
		do
			set_cardinality_zero_or_more
		end

end
	
