indexing

	description:

		"XPath if expressions"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_IF_EXPRESSION

inherit

	XM_XPATH_COMPUTED_EXPRESSION
		redefine
			simplify, evaluate_item, promote, iterator, sub_expressions
		end

creation

	make

feature {NONE} -- Initialization

	make (a_condition: XM_XPATH_EXPRESSION; a_then_expression: XM_XPATH_EXPRESSION; an_else_expression: XM_XPATH_EXPRESSION) is
			-- Establish invariant.
		require
				condition_not_void: a_condition /= Void
				else_not_void: an_else_expression /= Void
				then_not_void: a_then_expression /= Void
		do
			set_condition (a_condition)
			set_else_expression (an_else_expression)
			set_then_expression (a_then_expression)
			compute_static_properties
		ensure
				condition_set: condition = a_condition
				else_set: else_expression = an_else_expression
				then_set: then_expression = a_then_expression
		end

feature -- Access

	condition: XM_XPATH_EXPRESSION
			-- Conditional clause

	else_expression: XM_XPATH_EXPRESSION
			-- Else clause
	
	then_expression: XM_XPATH_EXPRESSION
			-- Then clause
	
	item_type: INTEGER is
			--Determine the data type of the expression, if possible;
			-- All expression return sequences, in general;
			-- This routine determines the type of the items within the
			-- sequence, assuming that (a) this is known in advance,
			-- and (b) it is the same for all items in the sequence.
		do
			Result := common_super_type (then_expression.item_type, else_expression.item_type)
		end

	sub_expressions: DS_ARRAYED_LIST [XM_XPATH_EXPRESSION] is
			-- Immediate sub-expressions of `Current'
		do
			create Result.make (3)
			Result.set_equality_tester (expression_tester)
			Result.put (condition, 1)
			Result.put (then_expression, 2)
			Result.put (else_expression, 3)
		end

	iterator (a_context: XM_XPATH_CONTEXT): XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_ITEM] is
			-- Iterates over the values of a sequence
		local
			a_boolean_value: XM_XPATH_BOOLEAN_VALUE
		do
			a_boolean_value := condition.effective_boolean_value (a_context)
			if not a_boolean_value.is_item_in_error and then a_boolean_value.value then
				Result := then_expression.iterator (a_context)
			else
				Result := else_expression.iterator (a_context)
			end
		end

feature -- Status report

	display (a_level: INTEGER; a_pool: XM_XPATH_NAME_POOL) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indent (a_level), "if (")
			std.error.put_string (a_string)
			std.error.put_new_line
			condition.display (a_level + 1, a_pool)
			a_string := STRING_.appended_string (indent (a_level), "then")
			std.error.put_string (a_string)
			std.error.put_new_line
			then_expression.display (a_level + 1, a_pool)
			a_string := STRING_.appended_string (indent (a_level), "else")
			std.error.put_string (a_string)
			std.error.put_new_line
			else_expression.display (a_level + 1, a_pool)				
		end

feature -- Optimization

	simplify: XM_XPATH_EXPRESSION is
			-- Simplify `Current'
		local
			a_value: XM_XPATH_VALUE
			a_boolean_value: XM_XPATH_BOOLEAN_VALUE
			an_if_expression: XM_XPATH_IF_EXPRESSION
			an_expression: XM_XPATH_EXPRESSION
		do
			an_if_expression := clone (Current)
			an_expression := condition.simplify
			an_if_expression.set_condition (an_expression)
			if an_expression.is_error then
				an_if_expression.set_last_error (an_expression.last_error)
			else
				a_value ?= condition
				if a_value /= Void then
					a_boolean_value := condition.effective_boolean_value (Void)
					if not a_boolean_value.is_item_in_error and then a_boolean_value.value then
						an_expression := then_expression.simplify
						an_if_expression.set_then_expression (an_expression)
						if an_expression.is_error then
							an_if_expression.set_last_error (an_expression.last_error)
						end
					else
						an_expression := else_expression.simplify
						an_if_expression.set_else_expression (an_expression)
						if an_expression.is_error then
							an_if_expression.set_last_error (an_expression.last_error)
						end						
					end
				else
					an_if_expression.set_then_expression (then_expression.simplify)
					an_if_expression.set_else_expression (else_expression.simplify)
				end
			end
			Result := an_if_expression
		end

	analyze (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Perform static analysis of an expression and its subexpressions	
		do
				check
					condition.may_analyze
				end
			condition.analyze (a_context)
			if condition.was_expression_replaced then set_condition (condition.replacement_expression) end
			if condition.is_error then
				set_last_error (condition.last_error)
			else
					check
						then_expression.may_analyze
					end
				then_expression.analyze (a_context)
				if then_expression.was_expression_replaced then set_then_expression (then_expression.replacement_expression) end
				if then_expression.is_error then
					set_last_error (then_expression.last_error)
				else
						check
							else_expression.may_analyze
						end
					else_expression.analyze (a_context)
					if else_expression.was_expression_replaced then set_else_expression (else_expression.replacement_expression) end
					if else_expression.is_error then
						set_last_error (else_expression.last_error)
					end
				end
				if not is_error then
					replacement_expression := simplify
					was_expression_replaced := True
				end
			end
			set_analyzed
		end

	promote (an_offer: XM_XPATH_PROMOTION_OFFER): XM_XPATH_EXPRESSION is
			-- Offer promotion for this subexpression
		local
			an_expression: XM_XPATH_IF_EXPRESSION
		do
			an_expression ?= an_offer.accept (Current)
				check
					an_expression_not_void: an_expression /= Void
				end
			if an_expression = Current then -- not accepted
				an_expression := clone (Current)
				an_expression.set_condition (condition.promote (an_offer))
				if an_offer.action = Unordered or else an_offer.action = Inline_variable_references then
					an_expression.set_then_expression (then_expression.promote (an_offer))
					an_expression.set_else_expression (else_expression.promote (an_offer))
				end
			end
			Result := an_expression
		end

feature -- Evaluation

	evaluate_item (a_context: XM_XPATH_CONTEXT) is
			-- Evaluate `Current' as a single item
		local
			a_boolean_value: XM_XPATH_BOOLEAN_VALUE
		do
			last_evaluated_item := Void
			a_boolean_value := condition.effective_boolean_value (a_context)
			if not a_boolean_value.is_item_in_error and then a_boolean_value.value then
				then_expression.evaluate_item (a_context)
			else
				else_expression.evaluate_item (a_context)
			end
		end

feature -- Element change

	set_condition (a_condition: XM_XPATH_EXPRESSION) is
			-- Set `condition'.
		require
			condition_not_void: a_condition /= Void
		do
			condition := a_condition
		ensure
			condition_set: condition = a_condition
		end

	set_then_expression (a_then_expression: XM_XPATH_EXPRESSION) is
			-- Set `then_expression'.
		require
			then_not_void: a_then_expression /= Void
		do
			then_expression := a_then_expression
		ensure
			then_set: then_expression = a_then_expression
		end

	set_else_expression (an_else_expression: XM_XPATH_EXPRESSION) is
			-- Set `else_expression'.
		require
			else_not_void: an_else_expression /= Void
		do
			else_expression := an_else_expression
		ensure
			else_set: else_expression = an_else_expression
		end	

feature {NONE} -- Implementation

	compute_cardinality is
			-- Compute cardinality.
		do
			todo ("compute-cardinality", False)
			-- TODO
		end
	
invariant

	condition_not_void: condition /= Void
	else_not_void: else_expression /= Void
	then_not_void: then_expression /= Void

end

	
