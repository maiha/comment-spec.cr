require "./spec_helper"

def each_suit(path)
  File.read_lines(path).each.select(&.=~ /^[^#\s]/).in_groups_of(2).each_with_index do |ary, i|
    src, dst = ary
    if dst
      yield(src.not_nil!, dst.not_nil!, i)
    else
      raise "BUG: invalid fixture size #{ary.size} in '#{path}':(suit: #{i})" unless ary.size == 2
    end
  end
end


describe "CI(fixutres)" do
  Dir["#{__DIR__}/fixtures/*"].sort.each do |full_path|
    label = File.basename(full_path)
    describe label do
      each_suit(full_path) do |src, dst|
        it src do
          CommentSpec.parse(src).should eq(dst)
        end
      end
    end
  end
end
