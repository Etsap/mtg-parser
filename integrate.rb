require 'fileutils'
require 'json'

filename = ARGV[0]

class Comma
	@comma = false
	def getComma
		return "," if @comma
		@comma = true
		return ""
	end
end

def get_next(input)
	chars = ""
	nest = 0
	begin
		loop do
			c = input.readchar
			break if nest == 0 && (c == "," || c == "]")
			chars += c
			if c == "{"
				nest += 1
			elsif c == "}"
				nest -= 1
			end
		end
		return JSON.parse(chars)
	rescue
		begin
			return JSON.parse(chars)
		rescue
		end
	end
	return nil
end

def add_card(current_card, added_card)
	copy_fields = ["rarity", "artist", "number", "multiverseid", "id"]
	added_card["printings"].each do |new_printing|
		next unless new_printing.has_key?("multiverseid")
		found = false
		current_card["printings"].each do |old_printing|
			if old_printing["set"] == new_printing["set"]
				if !old_printing.has_key?("multiverseid") || old_printing["multiverseid"] == new_printing["multiverseid"]
					copy_fields.each do |field|
						old_printing[field] = new_printing[field]
					end
					found = true
					break
				end
			end
		end
		unless found
			current_card["printings"] << new_printing
		end
	end
	return current_card
end

chars = ""
nest = 0
comma = Comma.new
puts "parsing #{filename}"
file = File.open(filename, "r:UTF-8")
gatherer = File.open("gatherer.json", "r:UTF-8")
temp_output = File.open("output.txt", "w:UTF-8")
old_card = get_next(gatherer)
10.times do
	file.readchar
end
new_card = get_next(file)
current_card = nil
added = 0
updated = 0
total = 0
loop do
	break if old_card == nil && current_card == nil && new_card == nil
	
	if current_card == nil 
		if (old_card == nil || new_card != nil && new_card["name"] < old_card["name"])
			puts "Adding #{new_card["name"]}"
			added += 1
			total += 1
			current_card = new_card
			new_card = get_next(file)
		else
			# puts "Keeping #{old_card["name"]}"
			total += 1
			current_card = old_card
			old_card = get_next(gatherer)
		end
	elsif new_card != nil && current_card["name"] == new_card["name"]
		puts "Updating #{current_card["name"]}"
		updated += 1
		current_card = add_card(current_card, new_card)
		new_card = get_next(file)
	else
		temp_output.write(comma.getComma + JSON.generate(current_card))
		current_card = nil
	end
end

file.close
gatherer.close
temp_output.close
File.rename("output.txt", "gatherer.json")
puts "New #{added}"
puts "Updates #{updated}"
puts "Total #{total}"

