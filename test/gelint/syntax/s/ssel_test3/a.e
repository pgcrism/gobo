note

	description:

		"Empty lines not allowed in multi-line manifest strings"

	library:    "Gobo Eiffel Tools Library"
	author:     "Eric Bezault <ericb@gobosoft.com>"
	copyright:  "Copyright (c) 1999, Eric Bezault and others"
	license:    "MIT License"
	date:       "$Date$"
	revision:   "$Revision$"

class A

create

	make

feature

	make
		do
			print ("first line %

				% third line")
		end

end -- class A
