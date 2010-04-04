class Array
  def delete_first(obj = nil, &block)
    index = if block
              self.index(&block)
            elsif obj
              self.index(obj)
            end
    index.nil? ? nil : self.delete_at(index)
  end
end
