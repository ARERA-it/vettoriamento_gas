require 'faker'
require 'nokogiri'
require 'yaml'
require 'erb'
require 'date'

input_file = '../empty_schema.xml'
final_file = '../esempi/example_01.xml'

xsd = Nokogiri::XML(File.read('../FlussoFattureGas.xsd'))

doc = Nokogiri::XML(File.read(input_file))

# Read XSD for getting the lists
classi_misuratore        = xsd.xpath("//xs:simpleType[@name='TClasseMisuratore']//xs:enumeration").map { |e| e['value'] }
tipi_pdr                 = xsd.xpath("//xs:simpleType[@name='TPDR']//xs:enumeration").map { |e| e['value'] }
ambiti_tariffari         = xsd.xpath("//xs:simpleType[@name='TAmbitoTariffario']//xs:enumeration").map { |e| e['value'] }
tipi_movimenti           = xsd.xpath("//xs:simpleType[@name='TTipoMovimento']//xs:enumeration").map { |e| e['value'] }
componenti_tariffarie    = xsd.xpath("//xs:simpleType[@name='TComponenteTariffaria']//xs:enumeration").map { |e| e['value'] }
# categorie_voci_fatturate = xsd.xpath("//xs:simpleType[@name='TCategoriaVoceFatturata']//xs:enumeration").map { |e| e['value'] }
modalita_pagamento       = xsd.xpath("//xs:simpleType[@name='TModalitaPagamento']//xs:enumeration").map { |e| e['value'] }
scaglioni                = 1.upto(9).to_a.map(&:to_s)

def regime_comp_bonus
  [
    'G',
    ['AC', 'R', 'ACR'].sample,
    [1,2].sample,
    ['A/B', 'C', 'D', 'E', 'F'].sample,
    ['d', 'i'].sample
  ].join('')
end


sender    = Faker::Company.name
recipient = Faker::Company.name

# Configurazione del generatore:
# - quanti PDR
# - quanti dettagli per PDR
# -

pdr_count = (7..14).to_a.sample
pdr_array = Array.new(pdr_count)
comp_tariff = []
comp_tariff_h = {} # memorizza le componenti tariffarie e gli imponibili. Servirà per calcolare le voci fattura

pdr_count.times do |i|
  ct = componenti_tariffarie.sample
  amounts_count = (5..9).to_a.sample
  hash = { amounts_count: amounts_count }
  amounts = []
  comp_tariff = []
  amounts_count.times do |j|
    a = (rand*100).round(3)
    amounts << a
    ct = componenti_tariffarie.sample
    comp_tariff << ct
    comp_tariff_h[ct] = 0.0 if !comp_tariff_h.has_key? ct
    comp_tariff_h[ct] += a
  end

  hash[:amounts] = amounts # amounts è un array di imponibili
  hash[:comp_tariff] = comp_tariff # comp_tariff è un array di componenti tariffarie
  pdr_array[i] = hash
end

puts pdr_array.inspect
puts comp_tariff_h.inspect

# imposto i riferimenti iva:
riva = [3,4,5].sample
riva_arr = Array.new(riva)
riva.times do |i|
  riva_arr[i] = {
    codice: Faker::Alphanumeric.alpha(number: 4).upcase,
    descrizione: Faker::Lorem.sentence,
    aliquota: [22.0, 22.0, 20.0, 10.0, 5.0].sample
  }
end

# imposto le voci fattura:
voci_fattura = []

comp_tariff_h.each do |k,v|
  voci_fattura << {
    categ_voce_fatt: k,
    cod_rif_iva: riva_arr.sample[:codice],
    aliquota: riva_arr.sample[:aliquota],
    imponibile: v
  }
end

# puts riva_arr.inspect
# puts voci_fattura.inspect

tot_imponibile = comp_tariff_h.values.sum
tot_iva = voci_fattura.map { |e| e[:imponibile] * e[:aliquota] / 100 }.sum
totale = tot_imponibile + tot_iva

# puts tot_imponibile
# puts tot_iva
# puts totale



Faker::Config.locale = 'it'

yaml_string = <<-YAML
FlussoFattureTrasportoGas:
  TestataFlusso:
    TipoFlusso: V
    DataCreazione: '2023-08-02'
    Versione: <%= Faker::App.version %>
    NumeroSequenza: 1

  Mittente:
    RagioneSociale: <%= sender %>
    PartitaIVA: <%= Faker::Company.swedish_organisation_number %>
    PartitaIVAGruppo: <%= Faker::Company.swedish_organisation_number %>
    CodiceFiscale: <%= Faker::Code.asin %>
    Indirizzo:
      Intestazione: <%= sender %>
      Indirizzo: <%= Faker::Address.street_address %>
      CAP: <%= Faker::Number.number(digits: 5) %>
      Localita: <%= Faker::Address.city %>
      Provincia: '<%= Faker::Address.state_abbr %>'
      Nazione: <%= Faker::Address.country_code %>
    Email: <%= Faker::Internet.email %>
    Telefono: <%= Faker::PhoneNumber.phone_number %>
    Pagamento:
      CondizioniPagamento: RIMESSA DIRETTA 30 GG FINE MESE
      ModalitaPagamento: <%= modalita_pagamento.sample %>
      IBAN: <%= Faker::Bank.iban(country_code: "it") %>

  Destinatario:
    RagioneSociale: <%= recipient %>
    PartitaIVA: <%= Faker::Company.swedish_organisation_number %>
    PartitaIVAGruppo: <%= Faker::Company.swedish_organisation_number %>
    CodiceFiscale: <%= Faker::Code.asin %>
    IndirizzoFatturazione:
      Intestazione: <%= recipient %>
      Indirizzo: <%= Faker::Address.street_address %>
      CAP: <%= Faker::Number.number(digits: 5) %>
      Localita: <%= Faker::Address.city %>
      Provincia: '<%= Faker::Address.state_abbr %>'
      Nazione: <%= Faker::Address.country_code %>
    IndirizzoSpedizione:
      Intestazione: <%= recipient %>
      Indirizzo: <%= Faker::Address.street_address %>
      CAP: <%= Faker::Number.number(digits: 5) %>
      Localita: <%= Faker::Address.city %>
      Provincia: '<%= Faker::Address.state_abbr %>'
      Nazione: <%= Faker::Address.country_code %>

  Fattura:
    Numero: <%= Faker::Number.number(digits: 6) %>
    DataEmissione: '2023-08-02'
    DataScadenza: '2023-08-30'
    TotaleImponibile: '<%= tot_imponibile.round(2).to_s.gsub('.',',') %>'
    TotaleIVA: '<%= tot_iva.round(2).to_s.gsub('.',',') %>'
    Totale: '<%= totale.round(2).to_s.gsub('.',',') %>'
    ImportoBollo: '2,00'
    Note: <%= Faker::Lorem.paragraph %>

    VociFattura:
    <% voci_fattura.each do |vf| %>
      - VoceFattura:
          CategoriaVoceFatturata: <%= vf[:categ_voce_fatt] %>
          CodiceRiferimentoIVA: <%= vf[:cod_rif_iva] %>
          Imponibile: '<%= vf[:imponibile].round(2).to_s.gsub('.',',') %>'
    <% end %>

    RiferimentiIVA:
    <% riva_arr.each do |ri| %>
      - RiferimentoIVA:
          Codice: <%= ri[:codice] %>
          Descrizione: <%= ri[:descrizione] %>
          Aliquota: '<%= ri[:aliquota].to_s.gsub('.',',') %>'
    <% end %>

  DettagliPDR:
  <% pdr_array.each do |pdr| %>
    - DettaglioPDR:
        CodicePDR: <%= Faker::Number.number(digits: 10) %>
        REMIPool: <%= Faker::Number.number(digits: 10) %>
        CodiceISTAT: <%= Faker::Number.number(digits: 6) %>
        Comune: <%= Faker::Address.city %>
        CoefficienteC: '<%= (1+0.1*(rand-0.5)).round(6).to_s.gsub('.',',') %>'
        Correttore: '<%= ['SI', 'NO'].sample %>'
        ProgrAnnoSolare: '<%= Faker::Number.decimal(l_digits: 6, r_digits: 3).to_s.gsub('.',',') %>'
        ClasseMisuratore: <%= classi_misuratore.sample %>
        TipoPDR: <%= tipi_pdr.sample %>
        AmbitoTariffario: <%= ambiti_tariffari.sample %>
        Importi:
        <% pdr[:amounts_count].times do |i| %>
          - Importo:
              DataInizio: '2023-08-01'
              DataFine: '2023-08-31'
              TipoMovimento: <%= tipi_movimenti.sample %>
              ComponenteTariffaria: <%= ct = pdr[:comp_tariff][i] %>
              <% if ct=='BONUS_SOC' %>RegimeCompensazioneBonus: <%= regime_comp_bonus %><% end %>
              <% if ct=='BONUS_SOC' %>CodiceBonusSII: <%= Faker::Number.number(digits: 10) %><% end %>
              Quota: '<%= ("%f" % (rand/100).round(6).to_s ).gsub('.',',') %>'
              <% if rand>0.3 %>Scaglione: <%= scaglioni.sample %><% end %>
              Quantita: '<%= Faker::Number.decimal(l_digits: 9, r_digits: 6).to_s.gsub('.',',') %>'
              Imponibile: '<%= pdr[:amounts][i].round(2).to_s.gsub('.',',') %>'
        <% end %>
  <% end %>

  ChiusuraFlusso:
    UltimoElementoSequenza: SI
YAML


def build_node(xml, node)
  node.each do |k, v|
    if v.is_a?(Array)
      xml.send(k) do
        v.each do |v2|
          build_node(xml, v2)
        end
      end
    elsif v.is_a?(Hash)
      xml.send(k) do
        build_node(xml, v)
      end
    else
      xml.send(k, v)
    end
  end
end



# genera 5 file di esempio:
5.times do |i|
  final_file = "../esempi/esempio_#{(i+1).to_s.rjust(2,'0')}.xml"
  puts "Generating #{final_file}"
  erb = ERB.new yaml_string
  # puts erb.result(binding)
  data = YAML.load(erb.result(binding))
  # puts data.inspect



  builder = Nokogiri::XML::Builder.new do |xml|
    build_node(xml, data)
  end
  xml_string = builder.to_xml
  # puts xml_string
  File.open(final_file, 'w') { |file| file.write(xml_string) }

end
