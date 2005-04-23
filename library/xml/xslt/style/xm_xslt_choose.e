indexing

	description:

		"xsl:choose element nodes"

	library: "Gobo Eiffel XSLT Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XSLT_CHOOSE

inherit

	XM_XSLT_STYLE_ELEMENT
		redefine
			make_style_element, validate, returned_item_type, mark_tail_calls
		end

creation {XM_XSLT_NODE_FACTORY}

	make_style_element

feature {NONE} -- Initialization
	
	make_style_element (an_error_listener: XM_XSLT_ERROR_LISTENER; a_document: XM_XPATH_TREE_DOCUMENT;  a_parent: XM_XPATH_TREE_COMPOSITE_NODE;
		an_attribute_collection: XM_XPATH_ATTRIBUTE_COLLECTION; a_namespace_list:  DS_ARRAYED_LIST [INTEGER];
		a_name_code: INTEGER; a_sequence_number: INTEGER) is
			-- Establish invariant.
		do
			is_instruction := True
			Precursor (an_error_listener, a_document, a_parent, an_attribute_collection, a_namespace_list, a_name_code, a_sequence_number)
		end

feature -- Status setting

	mark_tail_calls is
			-- Mark tail-recursive calls on templates and functions.
		local
			an_iterator: XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_NODE]
			a_style_element: XM_XSLT_STYLE_ELEMENT
		do
			from
				an_iterator := new_axis_iterator (Child_axis); an_iterator.start
			until
				an_iterator.after
			loop
				a_style_element ?= an_iterator.item
				if a_style_element /= Void then
					a_style_element.mark_tail_calls
				end
				an_iterator.forth
			end
		end

feature -- Element change

	prepare_attributes is
			-- Set the attribute list for the element.
		local
			a_cursor: DS_ARRAYED_LIST_CURSOR [INTEGER]
			a_name_code: INTEGER
			an_expanded_name: STRING
		do
			from
				a_cursor := attribute_collection.name_code_cursor
				a_cursor.start
			variant
				attribute_collection.number_of_attributes + 1 - a_cursor.index				
			until
				a_cursor.after
			loop
				a_name_code := a_cursor.item
				an_expanded_name := shared_name_pool.expanded_name_from_name_code (a_name_code)
				check_unknown_attribute (a_name_code)
				a_cursor.forth
			end
			attributes_prepared := True
		end

	validate is
			-- Check that the stylesheet element is valid.
		local
			a_child_iterator: XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_NODE]
			an_xsl_when: XM_XSLT_WHEN
			an_otherwise: XM_XSLT_OTHERWISE
			an_error: XM_XPATH_ERROR_VALUE
		do
			check_within_template
			from
				a_child_iterator := new_axis_iterator (Child_axis)
				a_child_iterator.start
			until
				any_compile_errors or else a_child_iterator.after
			loop
				an_xsl_when ?= a_child_iterator.item
				if an_xsl_when /= Void then
					if otherwise /= Void then
						create an_error.make_from_string ("xsl:otherwise must be immediately within xsl:choose", "", "XTSE0010", Static_error)
						report_compile_error (an_error)
					end
					number_of_whens := number_of_whens + 1
				else
					an_otherwise ?= a_child_iterator.item
					if an_otherwise /= Void then
						if otherwise /= Void then
							create an_error.make_from_string ("Only one xsl:otherwise is allowed within an xsl:choose", "", "XTSE0010", Static_error)
							report_compile_error (an_error)
						else
							otherwise := an_otherwise
						end
					elseif a_child_iterator.item.node_type = Text_node and then not is_all_whitespace (a_child_iterator.item.string_value) then
						create an_error.make_from_string ("Text node is not allowed inside xsl:choose", "", "XTSE0010", Static_error)
						report_compile_error (an_error)
					else
						create an_error.make_from_string ("Only xsl:when and xsl:otherwise are allowed within an xsl:choose", "", "XTSE0010", Static_error)
						report_compile_error (an_error)
					end
				end
				a_child_iterator.forth
			end
			if number_of_whens = 0 then
				create an_error.make_from_string ("xsl:choose must contain at least one xsl:when", "", "XTSE0010", Static_error)
				report_compile_error (an_error)
			end
			validated := True
		end

	compile (an_executable: XM_XSLT_EXECUTABLE) is
			-- Compile `Current' to an excutable instruction.
		local
			a_child_iterator: XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_NODE]
			a_when: XM_XSLT_WHEN
			an_otherwise: XM_XSLT_OTHERWISE
			a_condition: XM_XPATH_EXPRESSION
			an_action: XM_XPATH_EXPRESSION
		do
			top_stylesheet := principal_stylesheet
			compiled_actions_count := number_of_whens
			if otherwise /= Void then
				compiled_actions_count := compiled_actions_count + 1
			end
			create compiled_conditions.make (compiled_actions_count)
			create compiled_actions.make (compiled_actions_count)
			from
				compiled_actions_count := 0
				a_child_iterator := new_axis_iterator (Child_axis); a_child_iterator.start
			until
				has_compile_loop_finished or else a_child_iterator.after
			loop
				a_when ?= a_child_iterator.item
				if a_when /= Void then
					compile_when (an_executable, a_when)
				else
					an_otherwise ?= a_child_iterator.item
					check
						otherwise: an_otherwise /= Void
						-- validation has already checked for this
					end
					compiled_actions_count := compiled_actions_count + 1
					create {XM_XPATH_BOOLEAN_VALUE} a_condition.make (True)
					compiled_conditions.put_last (a_condition)
					compile_sequence_constructor (an_executable, an_otherwise.new_axis_iterator (Child_axis), True)
					an_action := last_generated_expression
					if an_action = Void then create {XM_XPATH_EMPTY_SEQUENCE} an_action.make end
					an_action.simplify
					if an_action.was_expression_replaced then an_action := an_action.replacement_expression end
					if an_action.is_error then
						report_compile_error (an_action.error_value)
					else					
						compiled_actions.put_last (an_action)
						has_compile_loop_finished := True
					end
				end
				if not has_compile_loop_finished then a_child_iterator.forth end
			end
			if compiled_actions_count = 0 then
				last_generated_expression := Void
			elseif compiled_actions_count = 1 then
				if compiled_conditions.item (1).is_boolean_value then
					if compiled_conditions.item (1).as_boolean_value.value then

						-- only one condition left, and it's known to be true: return the corresponding action
						
						last_generated_expression := compiled_actions.item (1)
					else

						-- but if it's false, return a no-op

						last_generated_expression := Void
					end
				else
					create {XM_XSLT_COMPILED_CHOOSE} last_generated_expression.make (an_executable, compiled_conditions, compiled_actions)
				end
			else
				create {XM_XSLT_COMPILED_CHOOSE} last_generated_expression.make (an_executable, compiled_conditions, compiled_actions)
			end
		end
	

feature {XM_XSLT_STYLE_ELEMENT} -- Restricted

	returned_item_type: XM_XPATH_ITEM_TYPE is
			-- Type of item returned by this instruction
		do
			Result := common_child_item_type
		end

feature {NONE} -- Implementation

	otherwise: XM_XSLT_OTHERWISE
			-- Otherwise clause

	number_of_whens: INTEGER
			-- Number of when clauses

	compiled_actions_count: INTEGER
			-- Number of when's + otherwise that are actually compiled

	has_compile_loop_finished: BOOLEAN
			-- Communication flag between `compile' and `compile_when'

	top_stylesheet:XM_XSLT_STYLESHEET
			-- Prinicpal stylesheet

	compiled_conditions: DS_ARRAYED_LIST [XM_XPATH_EXPRESSION]
			--	Conditions present in compiled instruction
	
	compiled_actions: DS_ARRAYED_LIST [XM_XPATH_EXPRESSION]
			-- Actions present in compiled instruction

	compile_when (an_executable: XM_XSLT_EXECUTABLE; a_when: XM_XSLT_WHEN) is
			-- Compile when clause.
		require
			executable_not_void: an_executable /= Void
			when_clause_not_void: a_when /= Void
		local
			a_condition, an_action: XM_XPATH_EXPRESSION
		do
			a_condition := a_when.condition
			compile_sequence_constructor (an_executable, a_when.new_axis_iterator (Child_axis), True)
			an_action := last_generated_expression
			if an_action = Void then create {XM_XPATH_EMPTY_SEQUENCE} an_action.make end
			an_action.simplify
			if an_action.was_expression_replaced then an_action := an_action.replacement_expression end
			if an_action.is_error then
				report_compile_error (an_action.error_value)
			else
				
				-- Optimize for constant conditions (true or false)
				
				if a_condition.is_boolean_value then
					if a_condition.as_boolean_value.value then
						compiled_actions_count := compiled_actions_count + 1
						compiled_conditions.put_last (a_condition)
						compiled_actions.put_last (an_action)
						has_compile_loop_finished := True
					else
						
						--  constant false: omit this test
						
					end
				else
					compiled_actions_count := compiled_actions_count + 1
					compiled_conditions.put_last (a_condition)
					compiled_actions.put_last (an_action)						
				end
			end
		end

invariant

	instruction: is_instruction = True

end
