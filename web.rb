ETMS_BASE_URL=ENV["ETMS_BASE_URL"]
DCAT = RDF::Vocabulary.new('http://www.w3.org/ns/dcat#')
DCTERMS = RDF::Vocabulary.new('http://purl.org/dc/terms/')

def publications
    result = query(%(
      PREFIX void: <http://rdfs.org/ns/void#>
      PREFIX dcat: <http://www.w3.org/ns/dcat#>
      PREFIX mu:      <http://mu.semte.ch/vocabularies/core/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      SELECT *
      FROM <#{Sinatra::Application.settings.graph}>
      WHERE
       {
        ?publication a void:Dataset;
                      mu:uuid ?id;
                      dcterms:title ?name;
                      dcterms:created ?created;
                      dcterms:modified ?modified;
                      <http://dbpedia.org/ontology/status> "official".
        OPTIONAL { ?publication dcterms:issued ?issued. }
        OPTIONAL { ?publication <http://dbpedia.org/ontology/filename> ?filename. }
      } ORDER BY DESC(?issued)
    ))

end

def dataset_iri(id)
  RDF::URI.new("http://data.europa.eu/esco/dcat/dataset/#{id}")
end

def distribution_iri(id)
  RDF::URI.new("#{dataset_iri(id)}/distribution")
end

def catalog_iri
  RDF::URI.new("http://data.europa.eu/esco/dcat/catalog")
end

get '/dcat' do
  content_type "text/plain"
  RDF::Writer.for(:ntriples).buffer do |writer|
    writer << [ catalog_iri, RDF.type, DCAT.Catalog ]
    publications.each do |pub|
      pub_id = pub["id"].value
      writer << [ catalog_iri, DCAT.dataset, dataset_iri(pub_id) ]
      writer << [ dataset_iri(pub_id), RDF.type, DCAT.Dataset ]
      writer << [ dataset_iri(pub_id), DCTERMS.title, pub.name ]
      writer << [ dataset_iri(pub_id), DCTERMS.issued, pub.issued ] 
      writer << [ dataset_iri(pub_id), DCTERMS.modified, pub.modified ]
      writer << [ dataset_iri(pub_id), DCTERMS.isVersionOf,   RDF::URI.new("http://data.europa.eu/dcat/dataset/esco") ]
      writer << [ dataset_iri(pub_id), DCAT.distribution, distribution_iri(pub_id) ]
      writer << [ distribution_iri(pub_id), DCAT.downloadURL, RDF::URI.new("#{ETMS_BASE_URL}/publications/#{pub_id}/download")]
      writer << [ distribution_iri(pub_id), DCAT.mediaType, "text/plain" ]
      writer << [ distribution_iri(pub_id), DCTERMS.format, "ntriples" ]
      writer << [ distribution_iri(pub_id), RDF.type, DCAT.Distribution ]
    end
  end   
end
