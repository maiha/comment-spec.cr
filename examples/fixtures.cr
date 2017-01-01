# convert given file as fixtures format

require "../src/comment-spec"

puts "# Tests are groups of two lines: source, expected"
puts "# Blank lines and lines starting with # are ignored"
puts

File.read_lines(ARGV.shift).each do |line|
  puts line
  puts CommentSpec.parse(line)
  puts
end
  
