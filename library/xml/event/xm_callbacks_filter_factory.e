indexing

	description:

		"Convenient class to create event filters"

	library: "Gobo Eiffel XML Library"
	copyright: "Copyright (c) 2002, Eric Bezault and others"
	license: "Eiffel Forum License v1 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_CALLBACKS_FILTER_FACTORY

feature -- Filters

	new_null: XM_CALLBACKS_NULL is
			-- New null callback consumer.
		do
			!! Result.make
		ensure
			new: Result /= Void
		end

	new_pretty_print: XM_PRETTY_PRINT_FILTER is
			-- New pretty printer (to standard io).
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_pretty_print_string (an_output: STRING): XM_PRETTY_PRINT_FILTER is	
			-- New pretty printer output to string.
		do
			Result := new_pretty_print
			Result.set_output_string (an_output)
		ensure
			new: Result /= Void
		end

	new_canonical_pretty_print: XM_CANONICAL_PRETTY_PRINT_FILTER is
			-- James Clark' canonical XML output.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_end_tag_checker: XM_END_TAG_CHECKER is
			-- New end tag checker filter.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_unicode_validation: XM_UNICODE_VALIDATION_FILTER is
			-- New unicode validation filter.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_namespace_resolver: XM_END_TAG_CHECKER is
			-- New namespace resolver.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_stop_on_error: XM_STOP_ON_ERROR_FILTER is
			-- New stop-on-error filter.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_shared_strings: XM_SHARED_STRINGS_FILTER is
			-- New shared strings filter.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

	new_tree_builder: XM_CALLBACKS_TO_TREE_FILTER is
			-- New tree construction filter.
		do
			!! Result.make_null
		ensure
			new: Result /= Void
		end

feature -- Pipes

	callbacks_pipe (a: ARRAY [XM_CALLBACKS_FILTER]): XM_CALLBACKS is
			-- Make a pipe,
			-- eg << new_tag_checker, new_pretty_print >>
			-- return first item of pipe.
		require
			not_void: a /= Void
			not_empty: a.count > 0
		local
			i: INTEGER
		do
			from
				i := a.lower
			until
				i >= a.upper -- skip last item
			loop
				a.item (i).set_next (a.item (i + 1))
				i := i + 1
			end
			Result := a.item (a.lower)
		ensure
			not_void: Result /= Void
		end

	standard_callbacks_pipe (a: ARRAY [XM_CALLBACKS_FILTER]): XM_CALLBACKS is
			-- Add elements to standard validation pipe, which
			-- begins with:
			--  tag check -> namespace resolver -> stop on error
		require
			not_void: a /= Void
		local
			a_last: XM_CALLBACKS_FILTER
		do
			a_last := new_stop_on_error
			Result := callbacks_pipe
				(<< new_end_tag_checker, new_namespace_resolver, a_last >>)
			a_last.set_next (callbacks_pipe (a))
		end

end
