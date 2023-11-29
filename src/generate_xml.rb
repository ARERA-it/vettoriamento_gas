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
categorie_voci_fatturate = xsd.xpath("//xs:simpleType[@name='TCategoriaVoceFatturata']//xs:enumeration").map { |e| e['value'] }
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


# voci fattura
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
      Nazione: <%= Faker::Address.country_code_long %>
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
      Nazione: <%= Faker::Address.country_code_long %>
    IndirizzoSpedizione:
      Intestazione: <%= recipient %>
      Indirizzo: <%= Faker::Address.street_address %>
      CAP: <%= Faker::Number.number(digits: 5) %>
      Localita: <%= Faker::Address.city %>
      Provincia: '<%= Faker::Address.state_abbr %>'
      Nazione: <%= Faker::Address.country_code_long %>

  Fattura:
    Numero: <%= Faker::Number.number(digits: 6) %>
    DataEmissione: '2023-08-02'
    DataScadenza: '2023-08-30'
    TotaleImponibile: '<%= Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s.gsub('.',',') %>'
    TotaleIVA: '<%= Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s.gsub('.',',') %>'
    Totale: <%= Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s.gsub('.',',') %>
    ImportoBollo: '<%= Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s.gsub('.',',') %>'
    Note: <%= Faker::Lorem.paragraph %>

    VociFattura:
    <% 3.times do %>
      - VoceFattura:
          CategoriaVoceFatturata: <%= categorie_voci_fatturate.sample %>
          CodiceRiferimentoIVA: <%= Faker::Alphanumeric.alpha(number: 5) %>
          Imponibile: '<%= Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s.gsub('.',',') %>'
    <% end %>

    RiferimentiIVA:
    <% 3.times do %>
      - RiferimentoIVA:
          Codice: <%= Faker::Alphanumeric.alpha(number: 5) %>
          Descrizione: <%= Faker::Lorem.sentence %>
          Aliquota: '<%= [22.0, 10.0, 5.0].sample.to_s.gsub('.',',') %>'
    <% end %>

  DettagliPDR:
  <% 4.times do %>
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
        <% 3.times do %>
          - Importo:
              DataInizio: '2023-08-01'
              DataFine: '2023-08-31'
              TipoMovimento: <%= tipi_movimenti.sample %>
              ComponenteTariffaria: <%= ct = componenti_tariffarie.sample %>
              <% if ct=='BONUS_SOC' %>RegimeCompensazioneBonus: <%= regime_comp_bonus %><% end %>
              <% if ct=='BONUS_SOC' %>CodiceBonusSII: <%= Faker::Number.number(digits: 10) %><% end %>
              Quota: '<%= (rand/100).round(6).to_s.gsub('.',',') %>'
              <% if rand>0.3 %>Scaglione: <%= scaglioni.sample %><% end %>
              Quantita: '<%= Faker::Number.decimal(l_digits: 9, r_digits: 6).to_s.gsub('.',',') %>'
              Imponibile: '<%= (rand*100).round(3).to_s.gsub('.',',') %>'
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




10.times do |i|
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
