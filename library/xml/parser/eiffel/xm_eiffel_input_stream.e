indexing

	description: 

		"Variant of KI_CHARACTER_INPUT_STREAM that accepts UTF16 and Latin1 and converts it to UTF8"

	library: "Gobo Eiffel XML Library"
	copyright: "Copyright (c) 2002, Eric Bezault and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

	--xml_specific_lt: "Detection assuming first char is < is XML specific"

class XM_EIFFEL_INPUT_STREAM

inherit

	KI_CHARACTER_INPUT_STREAM
	
	KL_SHARED_STANDARD_FILES
		export {NONE} all end
		
	KL_IMPORTED_STRING_ROUTINES
		export {NONE} all end

	UC_IMPORTED_UTF8_ROUTINES
		export {NONE} all end

	UC_IMPORTED_UTF16_ROUTINES
		export {NONE} all end

creation

	make, make_from_stream

feature {NONE} -- Initialization

	make (a_name: STRING) is
			-- Create a new stream based on file `a_name'.
		local
			a_file: KL_TEXT_INPUT_FILE
		do
			create a_file.make (a_name)
			a_file.open_read
			make_from_stream (a_file)
		end

	make_from_stream (a_stream: like impl) is
			-- Create a new stream based on `a_stream'.
		require
			a_stream_not_void: a_stream /= Void
			--at_start: stream empty or at start
		do
			impl := a_stream
			create utf_queue.make
			last_string := clone ("")
			encoding := Undetected
		ensure
			impl_set: impl = a_stream
		end

feature -- Set latin1

	set_latin_1 is
			-- Set latin1 character encoding input mode.
		require
			compatible_encoding: is_latin_1_compatible
		do
			encoding := Latin_1
		end
		
	is_latin_1_compatible: BOOLEAN is
			-- Can the current encoding be switched to latin-1?
		do
			Result := encoding = Utf_8
		ensure
			undetected: (encoding = Undetected) implies (not Result)
		end
		
feature -- Input

	read_character is
			-- Read the next item in input stream.
			-- Make the result available in `last_character'.
		do
			-- see 'last_character': it chooses from impl or the queue
			
			if encoding = Undetected then
				utf16_detect_read_character
				
				-- If detection has not put back read character in queue, 
				-- read from upstream, which may be empty if the stream 
				-- contains only the byte order character.
				if utf_queue.count = 0 and not impl.end_of_input then
					noqueue_read_character
				end	
			else
				if utf_queue.count > 0 then
					-- Last character was read from queue, remove it.
					utf_queue.remove
					-- Next character may or may not be from queue.
					if utf_queue.count = 0 and not impl.end_of_input then
						noqueue_read_character
					end
				else
					-- Straightforward case.
					noqueue_read_character
				end
			end				
		end
		
feature {NONE} -- Input

	noqueue_read_character is
			-- Read character after detection and when detection queue has 
			-- been flushed..
		require
			open_read: is_open_read
			not_end: not end_of_input
			detected: encoding /= Undetected
			queue_empty: utf_queue.count = 0
		do
			if encoding = Utf_8 then
				impl.read_character
			elseif encoding = Latin_1 then
				latin1_read_character
			else
				check
					utf_16: encoding = Utf16_msb_first or encoding = Utf16_msb_last
				end
				utf16_read_character
			end	
		end
		
feature -- Input

	read_string (nb: INTEGER) is
			-- Read at most `nb' characters from input stream.
			-- Make the characters that have actually been read
			-- available in `last_string'.
		local
			i: INTEGER
		do
			-- naive implementation.
			-- When the file is not UTF16 we could use
			-- impl.read_string; last_string := impl.last_string but 
			-- that would break the fact that `last_string' must 
			-- remain the same object. It would also require 
			-- to duplicate some of the detection handling.
			from
				last_string.wipe_out
				read_character
				i := nb
			until
				i = 0 or end_of_input
			loop
				last_string.append_character (last_character)
				read_character
				i := i - 1
			end
		end

	unread_character (an_item: CHARACTER) is
			-- Put `an_item' back in input stream.
			-- This item will be read first by the next
			-- call to a read routine.
		do
			utf_queue.force (an_item)
		end

feature -- Status report

	is_open_read: BOOLEAN is
			-- Can items be read from input stream?
		do
			Result := impl.is_open_read
		end

	end_of_input: BOOLEAN is
			-- Has the end of input stream been reached?
		do
			Result := utf_queue.count = 0 and impl.end_of_input
		end

feature -- Access

	name: STRING is
			-- Name of input stream
		do
			Result := impl.name
		end

	last_character: CHARACTER is
			-- Last character read.
		do 
			if utf_queue.count > 0 then
				Result := utf_queue.item
			else
				Result := impl.last_character
			end
		end

	last_string: STRING
			-- Last string read
			-- (Note: unlike the abstract specification, this _often_ but 
			-- not always returns the same object.)

feature {NONE} -- State

	encoding: INTEGER
			-- Input encoding, one of:

	Utf_8, Latin_1, Utf16_msb_first, Utf16_msb_last, Undetected: INTEGER is unique
			-- Utf_8: input already in UTF-8
			-- Latin_1: input in ISO 8859-1 (Latin-1)
			-- Utf16_msb_first: UTF-16 with most significant byte first.
			-- Utf16_msb_last: UTF-16 with least significant byte first.
			-- Undetected: before reading first two chars

	utf_queue: DS_LINKED_QUEUE [CHARACTER]
			-- Queue used in UTF16 mode

	impl: KI_CHARACTER_INPUT_STREAM
			-- Internal stream

feature {NONE} -- UTF16 implementation

	utf16_detect_read_character is
			-- Read first two chars of file to establish
			-- whether we are a UTF16 file.
		require
			not_detected: encoding = Undetected
			not_end: not impl.end_of_input
		local
			first_char, second_char: CHARACTER
		do
			encoding := Utf_8
			impl.read_character
			if not impl.end_of_input then
				first_char := impl.last_character
				impl.read_character
				if not impl.end_of_input then
					second_char := impl.last_character
						-- Check byte ordering character.
						-- If found, set found and do not forward as input.
					if utf16.is_endian_detection_character_most_first (first_char.code, second_char.code) then
						encoding := Utf16_msb_first
					elseif utf16.is_endian_detection_character_least_first (first_char.code, second_char.code) then
						encoding := Utf16_msb_last
					elseif (first_char.code = 0 and second_char = Lt_char) then 
							-- Check wide '<'.
						encoding := Utf16_msb_first
						utf_queue.force (Lt_char)
					elseif (first_char = Lt_char and second_char.code = 0) then
						encoding := Utf16_msb_last
						utf_queue.force (Lt_char)
					else
							-- Not UTF16
						utf_queue.force (first_char)
						utf_queue.force (second_char)
					end
				else
					utf_queue.force (first_char)
				end
			end
		ensure
			end_or_set: encoding /= Undetected
		end

	utf16_read_character is
			-- Read two characters at a time and fill queue with 
			-- UTF8 encoding of character.
		require
			utf16: (encoding = Utf16_msb_first) or (encoding = Utf16_msb_last)
			not_end: not impl.end_of_input
		local
			first_char, second_char: CHARACTER
			a_most, a_least: INTEGER
			a_high_surrogate: INTEGER
		do
			-- warning: error conditions not handled on premature end of input,
			-- partial characters do not produce output
			
			impl.read_character
			if not impl.end_of_input then
				first_char := impl.last_character
				impl.read_character
				if not impl.end_of_input then
					second_char := impl.last_character
					a_most := most_significant (first_char, second_char)
					a_least := least_significant (first_char, second_char)

					-- UTF16 surrogate?
					if utf16.is_surrogate (a_most) then
						-- the character is in the surrogate range
						if utf16.is_high_surrogate (a_most) then
							-- first value of a surrogate pair
							a_high_surrogate := utf16.least_10_bits (a_most, a_least)
							
							-- now get second part of surrogate pair
							impl.read_character
							if not impl.end_of_input then
								first_char := impl.last_character
								impl.read_character
								if not impl.end_of_input then
									second_char := impl.last_character
									a_most := most_significant (first_char, second_char)
									a_least := least_significant (first_char, second_char)
									if utf16.is_low_surrogate (a_most) then
										append_character (utf16.surrogate (a_high_surrogate, utf16.least_10_bits (a_most, a_least)))
									else
										-- error condition: unexpected second byte of a 
										-- surrogate pair
									end
								end
							end
						else
							-- error condition: unexpected second byte of a 
							-- surrogate pair.
						end
					else
						-- ordinary UTF16 character.
						append_character (a_most * 256 + a_least)
					end
				end
			end
		end
		
feature {NONE} -- Latin-1 implementation

	latin1_read_character is
			-- Read character from source and convert it to UTF8 if latin1 
			-- character (8th bit set).
		require
			latin1: encoding = Latin_1
		do
			impl.read_character
			if not impl.end_of_input then
				if impl.last_character.code >= 128 then
					append_character (impl.last_character.code)
				end
			end
		end
		
feature {NONE} -- Implementation

	append_character (a_char: INTEGER) is
			-- Append character from UTF16 code.
		require
			positive: a_char >= 0
			max_utf16: a_char < 65536
		local
			i, nb: INTEGER
			a_buffer: STRING
		do
			debug ("xml_parser")
				std.error.put_string ("[")
				std.error.put_string (a_char.out)
				std.error.put_string ("]")
			end
				-- Convert to UTF8
			a_buffer := utf8_buffer
			STRING_.wipe_out (a_buffer)
			utf8.append_code_to_utf8 (a_buffer, a_char)
			nb := a_buffer.count
			from i := 1 until i > nb loop
				utf_queue.force (a_buffer.item (i))
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	most_significant (first, second: CHARACTER): INTEGER is
			-- Most significant byte from incoming bytes.
		do
			if encoding = Utf16_msb_first then
				Result := first.code
			else
				Result := second.code
			end
		ensure
			result_byte: Result >= 0 and Result < 256
			first_or_second: Result = first.code or Result = second.code
		end

	least_significant (first, second: CHARACTER): INTEGER is
			-- Least significant byte from incoming bytes.
		do
			if encoding = Utf16_msb_first then
				Result := second.code
			else
				Result := first.code
			end
		ensure
			result_byte: Result >= 0 and Result < 256
			first_or_second: Result = first.code or Result = second.code
		end

feature {NONE} -- Constants

	Lt_char: CHARACTER is '<'

	utf8_buffer: STRING is
			-- Buffer for UTF-8 encoding
		once
			Result := STRING_.make (6)
		ensure
			utf8_buffer_not_void: Result /= Void
			string_type: Result.same_type ("")
		end

invariant
	
	last_string: last_string /= Void
	impl_not_void: impl /= Void
	queue_not_void: utf_queue /= Void
	
end