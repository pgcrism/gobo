indexing

	description:

		"XPath Unary Expressions"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2005, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class XM_XPATH_UNARY_EXPRESSION

inherit

	XM_XPATH_COMPUTED_EXPRESSION
		redefine
			sub_expressions, same_expression, simplify, promote, compute_special_properties,
			is_unary_expression, as_unary_expression
		end

feature {NONE} -- Initialization

	make_unary (an_operand: XM_XPATH_EXPRESSION) is
			-- Establish invariant
		require
			operand_not_void: an_operand /= Void
		do
			base_expression := an_operand
			adopt_child_expression (base_expression)
			initialized := True
		ensure
			base_expression_set: base_expression /= Void and then base_expression.same_expression (an_operand)
		end

feature -- Access

	base_expression: XM_XPATH_EXPRESSION
			-- Base_Expression

	is_unary_expression: BOOLEAN is
			-- Is `Current' a unary expression?
		do
			Result := True
		end

	as_unary_expression: XM_XPATH_UNARY_EXPRESSION is
			-- `Current' seen as a unary expression
		do
			Result := Current
		end

	item_type: XM_XPATH_ITEM_TYPE is
			-- Data type of the expression, when known
		do
			Result := base_expression.item_type
		end

	sub_expressions: DS_ARRAYED_LIST [XM_XPATH_EXPRESSION] is
			-- Immediate sub-expressions of `Current'
		do
			create Result.make (1)
			Result.set_equality_tester (expression_tester)
			Result.put (base_expression, 1)
		end

feature -- Comparison

	same_expression (other: XM_XPATH_EXPRESSION): BOOLEAN is
			-- Are `Current' and `other' the same expression?
		do
			if other.is_unary_expression then
				Result := base_expression.same_expression (other.as_unary_expression.base_expression)
			end
		end

feature -- Status report

	display (a_level: INTEGER) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indentation (a_level), "operator ")
			a_string := STRING_.appended_string (a_string, display_operator)
			std.error.put_string (a_string)
			std.error.put_new_line
			base_expression.display (a_level + 1)
		end

feature -- Optimization	

	simplify is
			-- Perform context-independent static optimizations
		do
			base_expression.mark_unreplaced -- in case it's a path expression replaced by `Current'
			base_expression.simplify
			if base_expression.is_error then
				set_last_error (base_expression.error_value)
			elseif base_expression.was_expression_replaced then
				set_base_expression (base_expression.replacement_expression)
			end
		end

	analyze (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Perform static analysis of an expression and its subexpressions
		do
			mark_unreplaced
			base_expression.mark_unreplaced -- in case it's a path expression replaced by `Current'
			base_expression.analyze (a_context)
			if base_expression.was_expression_replaced then
				set_base_expression (base_expression.replacement_expression)
			end
			if base_expression.is_error then
				set_last_error (base_expression.error_value)
			else

				-- If  operand value is, pre-evaluate the expression

				if base_expression.is_value then
					eagerly_evaluate (Void)
					set_replacement (last_evaluation)

					-- if early evaluation fails, suppress the error: the value might not be needed at run-time

					if is_error then
						error_value := Void
					end
				end
			end
		end
	
	promote (an_offer: XM_XPATH_PROMOTION_OFFER) is
			-- Promote this subexpression.
		do
			base_expression.mark_unreplaced -- in case it's a path expression replaced by `Current'
			base_expression.promote (an_offer)
			if base_expression.was_expression_replaced then set_base_expression (base_expression.replacement_expression) end
		end

feature -- Element change

	set_base_expression (an_operand: XM_XPATH_EXPRESSION) is
			-- Set `base_expression'.
		require
			operand_not_void: an_operand /= Void
		do
			base_expression := an_operand
			base_expression.mark_unreplaced
			adopt_child_expression (base_expression)
		ensure
			base_expression_set: base_expression = an_operand
			base_expression_not_marked_for_replacement: not base_expression.was_expression_replaced
		end

feature {XM_XPATH_EXPRESSION} -- Restricted

	compute_cardinality is
			-- Compute cardinality.
		do
			clone_cardinality (base_expression)
		end

	compute_special_properties is
			-- Compute special properties.
		do
			set_special_properties (base_expression.special_properties)
		end

	display_operator: STRING is
			-- Format `operator' for display
		deferred
		ensure
			display_operator_not_void: Result /= Void
		end

invariant

	base_expression: base_expression /= Void

end
	
