RSpec.shared_context 'Save and restore original python type map' do
  around do |example|
    begin
      original = PyCall::Conversions.instance_variable_get(:@python_type_map)
      PyCall::Conversions.instance_variable_set(:@python_type_map, original.dup)
      example.run
    ensure
      PyCall::Conversions.instance_variable_set(:@python_type_map, original)
    end
  end
end
