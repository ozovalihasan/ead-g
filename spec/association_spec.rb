require 'association'
require 'entity'
require 'ead'

def set_associations
  ObjectSpace.garbage_collect

  parsed_file = JSON.parse(File.read("#{__dir__}/association_spec_sample.json"))

  parsed_tables = parsed_file['tables']
  parsed_nodes = parsed_file['nodes']
  parsed_edges = parsed_file['edges']

  @tables = parsed_tables.map do |(id)|
    Table.new(id, parsed_tables[id])
  end

  Table.update_superclasses(parsed_tables)

  @nodes = parsed_nodes.map do |node|
    Entity.new(node)
  end

  Entity.dismiss_similar_ones

  @edges = parsed_edges.map do |edge|
    Association.new(edge)
  end
end

describe Association do
  describe 'by dismissing duplicated associations' do
    let(:entity1) { Entity.find_by_name('entity1') }
    let(:association1) { entity1.associations.first }
    let(:entity2) { Entity.find_by_name('entity2') }
    let(:association2) { entity2.associations.first }
    let(:entity3) { Entity.find_by_name('entity3') }
    let(:association3) { entity2.associations.last }
    let(:entity4) { Entity.find_by_name('entity4') }

    before do
      set_associations
      described_class.dismiss_similar_ones
    end

    describe '#initialize' do
      it 'is created correctly' do
        expect(association1.first_entity.class).to eq(Entity)
        expect(association1.name).to eq('has_many')
        expect(association1.reference_association == association1).to be(true)
        expect(association1.middle_entities_has_many).to eq([])
        expect(association1.middle_entities_has_one).to eq([])

        expect(entity2.associations.first).to eq(association2)
        expect(entity2.parent_associations.any?(association1)).to be(true)

        expect(entity2.parents_has_many.any?(entity1)).to be(true)
        expect(entity1.children_has_many.any?(entity2)).to be(true)
        expect(entity3.parents_has_one.any?(entity2)).to be(true)
        expect(entity2.children_has_one.any?(entity3)).to be(true)

        entity9 = Entity.find_by_name('entity9')

        entity10 = Entity.find_by_name('entity10')
        association4 = entity9.associations.find { |association| association.second_entity == entity10 }

        expect(association4.optional).to be(false)

        entity11 = Entity.find_by_name('entity11')
        association5 = entity9.associations.find { |association| association.second_entity == entity11 }

        expect(association5.optional).to be(true)

        entity12 = Entity.find_by_name('entity12')
        association6 = entity9.associations.find { |association| association.second_entity == entity12 }

        expect(association6.optional).to be(false)

        entity13 = Entity.find_by_name('entity13')
        association7 = entity9.associations.find { |association| association.second_entity == entity13 }

        expect(association7.optional).to be(true)
      end
    end

    describe '#optional?' do
      it 'returns whether the association is optional or not' do
        entity9 = Entity.find_by_name('entity9')
        entity11 = Entity.find_by_name('entity11')
        association5 = entity9.associations.find { |association| association.second_entity == entity11 }

        expect(association5.optional?).to be(true)
      end
    end

    describe '.check_middle_entities_include' do
      it "sets all middle entities of any 'through' association if the through entity of the association " \
         'is the given entity' do
        entity3 = Entity.find_by_name('entity3')
        entity8 = Entity.find_by_name('entity8')

        described_class.check_middle_entities_include(entity4)
        expect(entity3.children_has_one_through.map(&:id)).not_to include(entity4.id)
        expect(entity4.parents_has_one_through.map(&:id)).not_to include(entity3.id)

        described_class.check_middle_entities_include(entity2)
        expect(entity3.children_has_one_through.map(&:id)).to include(entity4.id)
        expect(entity4.parents_has_one_through.map(&:id)).to include(entity3.id)
        expect(entity3.children_has_one_through).to include(entity8)
        expect(entity8.parents_has_one_through).to include(entity3)
      end
    end

    describe '#set_middle_entity' do
      it "sets the middle entity of a 'through' association" do
        described_class.all_references.each(&:set_middle_entity)

        entity3 = Entity.find_by_name('entity3')
        entity5 = Entity.find_by_name('entity5')
        entity6 = Entity.find_by_name('entity6')
        entity7 = Entity.find_by_name('entity7')
        entity8 = Entity.find_by_name('entity8')

        association = entity7.associations.find(&:through?)
        expect(association.middle_entities_has_one).to include(entity5)
        expect(entity7.children_has_one_through).to include(entity6)
        expect(entity6.parents_has_one_through).to include(entity7)

        association2 = entity2.associations.find(&:through?)
        expect(association2.middle_entities_has_many).to include(entity7)

        expect(entity3.children_has_many_through).to include(entity7)
        expect(entity7.parents_has_many_through).to include(entity3)

        expect(entity3.children_has_many_through).to include(entity5)
        expect(entity5.parents_has_many_through).to include(entity3)

        expect(entity3.children_has_one_through).to include(entity4)
        expect(entity4.parents_has_one_through).to include(entity3)

        expect(entity3.children_has_one_through).to include(entity8)
        expect(entity8.parents_has_one_through).to include(entity3)
      end
    end

    describe '#update_model_from_entity' do
      it 'calls Entity#update_model' do
        allow_any_instance_of(Entity).to receive(:update_model) do |first_entity, second_entity, association|
          expect([first_entity.name, second_entity.name, association.name]).to eql(%w[entity1 entity2 has_many])
        end

        association1.update_model_from_entity
      end
    end

    describe '#has_many?' do
      it "returns whether an instance's name is 'has_many'" do
        expect(association1.has_many?).to be(true)
      end
    end

    describe '#has_one?' do
      it "returns whether an instance's name is 'has_one'" do
        expect(association2.has_one?).to be(true)
      end
    end

    describe '#has_any?' do
      it "returns whether an instance's name is 'has_many' or 'has_one'" do
        expect(association1.has_any?).to be(true)
        expect(association2.has_any?).to be(true)
      end
    end

    describe '#through?' do
      it "returns whether an instance's name is ':through'" do
        expect(association3.through?).to be(true)
      end
    end

    describe '.all_references' do
      it 'returns all reference associations' do
        expect(described_class.all_references.size).to eq(19)
      end
    end

    describe '.all' do
      it 'returns all created instances' do
        expect(described_class.all.size).to eq(23)
      end
    end
  end

  describe 'without dismissing duplicated associations' do
    before do
      set_associations
    end

    describe '.dismiss_similar_ones' do
      it 'returns all reference associations' do
        expect(described_class.all_references.size).to eq(23)

        described_class.dismiss_similar_ones

        entity9 = Entity.find_by_name('entity9').reference_entity
        entity10 = Entity.find_by_name('entity10').reference_entity
        entity11 = Entity.find_by_name('entity11').reference_entity
        entity12 = Entity.find_by_name('entity12').reference_entity
        entity13 = Entity.find_by_name('entity13').reference_entity

        associations_between_entity9_and_entity13 = described_class.all.find_all do |association|
          association.first_entity == entity9 && association.second_entity == entity13
        end

        expect(associations_between_entity9_and_entity13.size).to eq(2)
        expect(associations_between_entity9_and_entity13.map(&:reference_association).uniq.size).to eq(1)
        expect(associations_between_entity9_and_entity13.first.reference_association.optional?).to be(true)
        expect(associations_between_entity9_and_entity13.count do |association|
                 association.reference_association == association
               end).to eq(1)

        associations_between_entity12_and_entity11 = described_class.all.find_all do |association|
          association.first_entity == entity12 && association.second_entity == entity11
        end

        expect(associations_between_entity12_and_entity11.size).to eq(2)
        expect(associations_between_entity12_and_entity11.map(&:reference_association).uniq.size).to eq(1)
        expect(associations_between_entity12_and_entity11.count do |association|
                 association.reference_association == association
               end).to eq(1)

        associations_between_entity9_and_entity12 = described_class.all.find_all do |association|
          association.first_entity == entity9 && association.second_entity == entity12
        end

        expect(associations_between_entity9_and_entity12.size).to eq(2)
        expect(associations_between_entity9_and_entity12.map(&:reference_association).uniq.size).to eq(1)
        expect(associations_between_entity9_and_entity12.first.reference_association.optional?).to be(false)
        expect(associations_between_entity9_and_entity12.count do |association|
                 association.reference_association == association
               end).to eq(1)

        associations_between_entity9_and_entity10 = described_class.all.find_all do |association|
          association.first_entity == entity9 && association.second_entity == entity10
        end

        expect(associations_between_entity9_and_entity10.size).to eq(2)
        expect(associations_between_entity9_and_entity10.map(&:reference_association).uniq.size).to eq(2)
        expect(associations_between_entity9_and_entity10.count do |association|
                 association.reference_association == association
               end).to eq(2)

        expect(described_class.all_references.size).to eq(19)
      end
    end
  end
end
