# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautAllergyIntoleranceSequence < SequenceBase
      group 'Argonaut Profile Conformance'

      title 'Allergy Intolerance'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARAI'

      requires :token, :patient_id
      conformance_supports :AllergyIntolerance

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert (resource.patient&.reference&.include?(value)), 'Patient on resource does not match patient requested'
        end
      end

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Allergy Intolerance Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/, '')}/?patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it contains:

        * The status of the allergy
        * A code representing the substance responsible for the allergy
        * A reference to the patient to whom the allergy belongs

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/, '')}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/medicationorder.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html)
              )

      @resources_found = false

      test 'Server rejects AllergyIntolerance search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An AllergyIntolerance search does not work without proper authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from AllergyIntolerance search by patient' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's allergies.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id }
        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
      end

      test 'Server returns expected results from AllergyIntolerance read resource' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance history resource supported' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        validate_history_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance vread resource supported' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html'
          desc %(
            AllergyIntolerance resources associated with Patient conform to Argonaut profiles
          )
          versions :dstu2
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance')
      end

      test 'All references can be resolved' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the AllergyIntolerance resource should be resolveable.
          )
          versions :dstu2
        end

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@allergyintolerance)
      end
    end
  end
end
