# :WIP:
# extract spec from README.md

require "../src/comment-spec"

puts "# Generated by #{File.basename(__FILE__)}"
puts
puts %(require "./spec_helper")
puts
puts %(describe "README.md" do)
puts %(  it "Usage" do)

File.read(__DIR__ + "/../README.md").scan(/^```crystal\n(.*?)\n```\n/m) do |code|
  code[1].split(/\n/).each do |line|
    puts "    %s" % CommentSpec::Parser.parse(line)
  end
end

puts %(  end)
puts %(end)

