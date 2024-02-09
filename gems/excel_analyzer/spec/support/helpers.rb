def fake_blob(io: nil, content_type:)
  dbl = double(io: io, content_type: content_type)
  allow(dbl).to receive(:open).and_yield(io)
  dbl
end
