# Copyright (C) 2016 Dmitry Yakimenko (detunized@gmail.com).
# Licensed under the terms of the MIT license. See LICENCE for details.

require "spec_helper"

describe Dashlane::Parser do
    let(:password) { "password" }
    let(:salt) { "salt" * 8 }
    let(:content) { "All your base are belong to us" }
    let(:accounts) { [
        Dashlane::Account.new("1",
                              "dude",
                              "jeffrey.lebowski",
                              "logjammin",
                              "https://dude.com",
                              "Get a new rug!"),
        Dashlane::Account.new("2",
                              "walter",
                              "walter.sobchak",
                              "worldofpain",
                              "https://nam.com",
                              "Don't roll on Shabbos!"),
    ] }

    describe ".parse_encrypted_blob" do
        it "parses KWC3 blob" do
            version = "KWC3"
            expected = {
                           salt: salt,
                     ciphertext: content,
                     compressed: true,
                use_derived_key: false,
                     iterations: 1,
                        version: version

            }

            expect(Dashlane::Parser.parse_encrypted_blob salt + version + content)
                .to eq expected
        end

        it "parses legacy blob" do
            expected = {
                           salt: salt,
                     ciphertext: content,
                     compressed: false,
                use_derived_key: true,
                     iterations: 5,
                        version: ""

            }

            expect(Dashlane::Parser.parse_encrypted_blob salt + content)
                .to eq expected
        end
    end

    describe ".compute_encryption_key" do
        let(:encryption_key) { "OAIU9FREAugcAkNtoeoUithzi2qXJQc6Gfj5WgPD0mY=".decode_base64 }

        it "returns an encryption key" do
            expect(Dashlane::Parser.compute_encryption_key password, salt).to eq encryption_key
        end
    end

    describe ".sha1" do
        def check times, expected
            expect(Dashlane::Parser.sha1 content, times).to eq expected
        end

        it "returns SHA1 checksum" do
            check 1, "xgmXgTCENlJpbnSLucn3NwPXkIk=".decode_base64
            check 5, "RqcjtwJ5KY1MON7n3WwvqGhrrpg=".decode_base64
        end
    end

    describe ".derive_encryption_key_iv" do
        let(:encryption_key) { "OAIU9FREAugcAkNtoeoUithzi2qXJQc6Gfj5WgPD0mY=".decode_base64 }

        def check iterations, expected
            expect(Dashlane::Parser.derive_encryption_key_iv encryption_key, salt, iterations)
                .to eq expected
        end

        it "returns an encryption key and IVs" do
            check 1, {
                key: "6HA2Rq9GTeKzAc1imNjvyaXBGW4zRA5wIr60Vbx/o8w=".decode_base64,
                 iv: "fCk2EkpIYGn05JHcVfR8eQ==".decode_base64
            }

            check 5, {
                key: "fsuGfEOoYL4uOmp24ZuAExIuVePh6YIu7t0rfCDogpM=".decode_base64,
                iv: "/vsHfrsRzyGCQOBP4UEQuw==".decode_base64
            }
        end
    end

    describe ".decrypt_aes256" do
        let(:ciphertext) { "TZ1+if9ofqRKTatyUaOnfudletslMJ/RZyUwJuR/+aI=".decode_base64 }
        let(:iv) { "YFuiAVZgOD2K+s6y8yaMOw==".decode_base64 }
        let(:encryption_key) { "OfOUvVnQzB4v49sNh4+PdwIFb9Fr5+jVfWRTf+E2Ghg=".decode_base64 }

        it "returns decrypted plaintext" do
            expect(Dashlane::Parser.decrypt_aes256 ciphertext, iv, encryption_key).to eq content
        end
    end

    describe ".inflate" do
        let(:compressed) { "c8zJUajMLy1SSEosTlVILEpVSErNyc9LVyjJVygtBgA=".decode_base64 }

        it "returns inflated content" do
            expect(Dashlane::Parser.inflate compressed).to eq content
        end
    end

    describe ".decrypt_blob" do
        let(:blob) { "c2FsdHNhbHRzYWx0c2FsdHNhbHRzYWx0c2FsdHNhbHRLV0MzxDNg8kGh5rSYkNvXzzn+3xsCKXS" +
                     "KgGhb2pGnbuqQo32blVfJpurp7jj8oSnzxa66" }

        it "returns decrypted content" do
            expect(Dashlane::Parser.decrypt_blob blob, password).to eq content
        end
    end

    describe ".extract_accounts_from_xml" do
        let(:accounts_xml) { %q{
            <KWAuthentifiant>
                <KWDataItem key="Title"><![CDATA[dude]]></KWDataItem>
                <KWDataItem key="Login"><![CDATA[jeffrey.lebowski]]></KWDataItem>
                <KWDataItem key="Password"><![CDATA[logjammin]]></KWDataItem>
                <KWDataItem key="Url"><![CDATA[https://dude.com]]></KWDataItem>
                <KWDataItem key="Note"><![CDATA[Get a new rug!]]></KWDataItem>
            </KWAuthentifiant>
            <KWAuthentifiant>
                <KWDataItem key="Title"><![CDATA[walter]]></KWDataItem>
                <KWDataItem key="Login"><![CDATA[walter.sobchak]]></KWDataItem>
                <KWDataItem key="Password"><![CDATA[worldofpain]]></KWDataItem>
                <KWDataItem key="Url"><![CDATA[https://nam.com]]></KWDataItem>
                <KWDataItem key="Note"><![CDATA[Don't roll on Shabbos!]]></KWDataItem>
            </KWAuthentifiant>
        } }

        def check xml, expected
            expect(Dashlane::Parser.extract_accounts_from_xml xml).to eq expected
        end

        it "returns an empty array when no accounts present" do
            check "<root />", []
        end

        it "returns accounts at level 1" do
            check "<root>#{accounts_xml}</root>", accounts
        end

        it "returns accounts at level 2" do
            check "<root><subroot>#{accounts_xml}</subroot></root>", accounts
        end
    end

    describe ".extract_encrypted_accounts" do
        let(:blob) { "c2FsdHNhbHRzYWx0c2FsdHNhbHRzYWx0c2FsdHNhbHRLV0MzAxW0NQiQrbiEe4yl26GagNu1edW" +
                     "/lK/INVrdUkE1+nmpiTZHlNkKKSK5NXbWGuztnk3256De1/2GtaUXjTKOMYvheV3TJJZWHKHEbS" +
                     "BHJ63OXH/svTCBm1yncDDcqWicVOjQwzP5C4oTmRB9jCAE9A7kx8bZjz2VQaAAxbKWwCFCSrzFX" +
                     "B22R6DwH+rpnKshrcHiflI8Fy2o000mU1XRhk1yFNqYZkiJBH0N3aJR7AkqRRALhUaLsMgYWsCx" +
                     "PqD9dP0dsp7A03htUKllVMfjfRexwJfJGi2ezSUvegGVt3k=" }

        it "returns an account" do
            expect(Dashlane::Parser.extract_encrypted_accounts blob, password).to eq accounts
        end
    end
end
