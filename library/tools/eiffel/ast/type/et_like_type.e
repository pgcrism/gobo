indexing

	description:

		"Eiffel anchored types"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2003, Eric Bezault and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class ET_LIKE_TYPE

inherit

	ET_TYPE

	HASHABLE

feature -- Access

	like_keyword: ET_KEYWORD is
			-- 'like' keyword
		deferred
		end

	direct_base_class (a_universe: ET_UNIVERSE): ET_CLASS is
			-- Class on which current type is directly based
			-- (e.g. a Class_type, a Tuple_type or a Bit_type);
			-- Return Void if not directly based on a class
			-- (e.g. Anchored_type). `a_universe' is the
			-- surrounding universe holding all classes.
		do
			-- Result := Void
		ensure then
			no_direct_base_type: Result = Void
		end

feature {NONE} -- Constants

	like_space: STRING is "like "
			-- Eiffel keywords

invariant

	like_keyword_not_void: like_keyword /= Void

end