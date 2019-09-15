require 'fileutils'
require 'json'

filename = ARGV[0] || "*.json"

opener = '{"cards":['
sets = {}
sets = JSON.parse(File.read("sets.json"))

def process_entry(entry, final_array, sets)
	my_json = JSON.parse(entry)
	my_json.delete("imageUrl")
	my_json.delete("foreignNames")
	my_json.delete("originalText")
	my_json.delete("originalType")
	my_json.delete("legalities")
	my_json.delete("variations")
	sets[my_json["set"]] = {"name" => my_json["setName"]} unless sets.has_key?(my_json["set"])
	my_json.delete("setName")
	if my_json.has_key?("set")
		move_fields = ["rarity", "set", "artist", "number", "multiverseid", "id"]
		printings = my_json["printings"]
		my_json["printings"] = []
		found = false
		printings.each do |printing|
			new_printing = {}
			if my_json["set"] == printing
				move_fields.each do |field|
					new_printing[field] = my_json[field]
					my_json.delete(field)
				end
				found = true
			elsif printing.is_a? String
				new_printing = {"set" => printing}
			else
				new_printing = printing
			end
			my_json["printings"] << new_printing
		end
		unless found
			new_printing = {}
			move_fields.each do |field|
				new_printing[field] = my_json[field]
				my_json.delete(field)
			end
			my_json["printings"] << new_printing
		end
	end
	final_array["cards"] << my_json
end

Dir.chdir('Raw')
Dir[filename].each do |filename|
	phase = 0
	chars = ''
	nest = 0
	puts "parsing #{filename}"
	success = false
	file = File.open(filename, "r:UTF-8")
	final_array = {"cards" => []}
	file.each_char do |c|
		if phase == 0
			chars += c
			if chars == opener
				phase = 1
				chars = ''
			elsif chars.length > 10
				puts "Error beginning file #{filename}"
				puts chars
				gets
				break
			end
		elsif phase == 1
			if nest == 0 && c == "]"
				process_entry(chars, final_array, sets)
				chars = "]"
				phase = 2
			else
				if nest == 0 && c == ","
					process_entry(chars, final_array, sets)
					chars = ''
					phase = 2 if c == "]"
				else
					chars += c
					if c == "{"
						nest += 1
					elsif c == "}"
						nest -= 1
					end
				end
			end
		else
			chars += c
			if chars != ']}'
				puts "Error ending file #{filename}"
				puts chars
				gets
				break
			else
				success = true
			end
		end
	end
	file.close
	if success
		output = File.open("output.txt","w")
		final_array["cards"].sort!{|a, b| a["name"] <=> b["name"]}
		output.write(JSON.generate(final_array))
		output.close
		File.rename("output.txt", filename)
	end
	file = File.open("..\\sets.json", "w")
	file.write(JSON.generate(sets))
	file.close
end

