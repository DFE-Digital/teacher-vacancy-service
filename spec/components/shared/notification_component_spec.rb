require "rails_helper"

RSpec.describe Shared::NotificationComponent, type: :component do
  let(:variant) { "notice" }
  let(:icon) { false }
  let(:body) { "This is content" }
  let(:links) { nil }
  let(:title) { nil }
  let(:dismiss) { true }
  let(:background) { false }

  let(:kwargs) {
    { variant: variant,
      icon: icon,
      links: links,
      dismiss: dismiss,
      background: background,
      title: title,
      body: body }
  }

  let!(:inline_component) do
    render_inline(described_class.new(**kwargs))
  end

  describe "content" do
    context "when content is a string" do
      it "renders content in the body" do
        expect(inline_component.css(".govuk-notification__body").to_html).to include("This is content")
      end
    end

    context "when content is a hash" do
      let(:title) { "Title" }
      let(:body) { "This is the body" }

      it "renders the title" do
        expect(inline_component.css(".govuk-notification__title").to_html).to include("Title")
      end

      it "renders the body" do
        expect(inline_component.css(".govuk-notification__body").to_html).to include("This is the body")
      end
    end
  end

  describe "dismiss" do
    context "when dismiss is true" do
      it "applies correct class" do
        expect(inline_component.css(".js-dismissible")).to_not be_blank
      end

      it "renders the dismiss link" do
        expect(inline_component.css(".dismiss-link").to_html).to include(I18n.t("buttons.dismiss"))
      end
    end

    context "when dismiss is false" do
      let(:dismiss) { false }

      it "applies correct class" do
        expect(inline_component.css(".js-dismissible")).to be_blank
      end

      it "does not render the dismiss link" do
        expect(rendered_component).to_not include(I18n.t("buttons.dismiss"))
      end
    end
  end

  describe "style" do
    context "when style is notice" do
      it "applies correct class" do
        expect(inline_component.css(".govuk-notification--notice")).to_not be_blank
      end

      context "when alert is true" do
        let(:icon) { true }

        it "applies the icon class" do
          expect(inline_component.css(".icon")).to_not be_blank
        end
      end

      context "when alert is false" do
        it "does not apply the icon class" do
          expect(inline_component.css(".icon")).to be_blank
        end
      end
    end

    context "when style is success" do
      let(:variant) { "success" }
      let(:icon) { true }

      it "applies correct class" do
        expect(inline_component.css(".govuk-notification--success")).to_not be_blank
      end

      it "does not apply the icon class" do
        expect(inline_component.css(".icon")).to be_blank
      end
    end

    context "when style is danger" do
      let(:variant) { "danger" }
      let(:icon) { true }

      it "does not render the dismiss link" do
        expect(rendered_component).to_not include(I18n.t("buttons.dismiss"))
      end

      it "applies correct class" do
        expect(inline_component.css(".govuk-notification--danger")).to_not be_blank
      end

      it "does not apply the icon class" do
        expect(inline_component.css(".icon")).to be_blank
      end
    end
  end

  describe "background" do
    context "when background is true" do
      let(:background) { true }

      it "applies the background class" do
        expect(inline_component.css(".govuk-notification__background")).to_not be_blank
      end
    end

    context "when background is false" do
      it "does not apply the background class" do
        expect(inline_component.css(".govuk-notification__background")).to be_blank
      end
    end
  end

  describe "links" do
    context "when links are supplied" do
      let(:links) { { first: "This is a test link", second: "This is another link" } }

      it "renders the links list" do
        expect(inline_component.css(".govuk-notification__list")).to_not be_blank
      end

      it "renders the first link" do
        expect(inline_component.css(".govuk-notification__list").to_html).to include(
          '<a class="govuk-link govuk-link--no-visited-state" href="#first">This is a test link</a>',
        )
      end

      it "renders the second link" do
        expect(inline_component.css(".govuk-notification__list").to_html).to include(
          '<a class="govuk-link govuk-link--no-visited-state" href="#second">This is another link</a>',
        )
      end
    end
  end

  describe "html_attributes" do
    subject { inline_component.css(".govuk-notification").to_html }

    context "when no html attributes are specified" do
      it "has the default role and tab-index" do
        expect(subject).to include('role="alert"')
        expect(subject).to include('tabindex="-1"')
      end

      context "when the style is empty" do
        let(:variant) { "empty" }

        it "has no html_attributes" do
          expect(subject).not_to include('role="alert"')
          expect(subject).not_to include('tabindex="-1"')
        end
      end
    end

    context "when html attributes are specified" do
      let!(:inline_component) do
        render_inline(described_class.new(**kwargs.merge(html_attributes: { role: "fake-role" })))
      end

      it "has the specified html_attributes and does not have the default role and tab-index" do
        expect(subject).not_to include('role="alert"')
        expect(subject).not_to include('tabindex="-1"')
        expect(subject).to include('role="fake-role"')
      end

      context "when the style is empty" do
        let(:variant) { "empty" }

        it "has the specified html_attributes and does not have the default role and tab-index" do
          expect(subject).not_to include('role="alert"')
          expect(subject).not_to include('tabindex="-1"')
          expect(subject).to include('role="fake-role"')
        end
      end
    end
  end

  it_behaves_like "a component that accepts custom classes"
  it_behaves_like "a component that accepts custom HTML attributes"
end
