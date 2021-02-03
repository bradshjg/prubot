require 'prubot'

on 'test-event', 'say howdy' do
  'howdy'
end

on 'test-action', 'test-event', 'say hello' do
  'hello'
end
