class Hash
  def except key
    clone.tap{|_| _.delete(key)}
  end
end
