defmodule UrielmWeb.TermsLive do
  use UrielmWeb, :live_view

  @sections [
    {1, "Our services"},
    {2, "Intellectual property rights"},
    {3, "User representations"},
    {4, "Prohibited activities"},
    {5, "User-generated contributions"},
    {6, "Contribution license"},
    {7, "Services management"},
    {8, "Term and termination"},
    {9, "Modifications and interruptions"},
    {10, "Governing law"},
    {11, "Dispute resolution"},
    {12, "Corrections"},
    {13, "Disclaimer"},
    {14, "Limitations of liability"},
    {15, "Indemnification"},
    {16, "User data"},
    {17, "Electronic communications and signatures"},
    {18, "Miscellaneous"},
    {19, "Contact us"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Terms of Use")
     |> assign(
       :meta_description,
       "Review the terms governing access to and use of urielm.dev and related SMPL LABS LLC services."
     )
     |> assign(:canonical_url, "https://urielm.dev/terms")
     |> assign(:sections, @sections)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="terms"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="terms-page" class="ui-page-shell max-w-6xl">
        <header class="ui-page-header">
          <div class="ui-page-heading">
            <p class="ui-eyebrow">SMPL LABS LLC</p>
            <h1 id="terms-title" class="ui-section-title">Terms of Use</h1>
            <p id="terms-updated" class="ui-section-copy mt-2">
              Last updated August 25, 2026
            </p>
          </div>
        </header>

        <div class="grid gap-6 lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start">
          <aside class="lg:sticky lg:top-24 lg:self-start">
            <nav
              id="terms-table-of-contents"
              aria-label="Terms of use sections"
              class="card ui-card ui-card-compact h-auto"
            >
              <div class="card-body gap-1 p-5">
                <h2 class="mb-2 text-sm font-black text-base-content">On this page</h2>
                <%= for {number, title} <- @sections do %>
                  <a
                    href={"#terms-section-#{number}"}
                    class="rounded-lg px-2 py-1.5 text-xs leading-snug text-base-content/60 transition-colors hover:bg-primary/8 hover:text-primary focus-visible:outline-2 focus-visible:outline-primary"
                  >
                    <span class="font-bold text-base-content/80">{number}.</span> {title}
                  </a>
                <% end %>
              </div>
            </nav>
          </aside>

          <main class="min-w-0 space-y-5">
            <section class="card ui-card h-auto border-primary/30 bg-primary/6">
              <div class="card-body gap-4 p-6 sm:p-8">
                <p class="text-xs font-black uppercase tracking-[0.16em] text-primary">
                  Agreement to our legal terms
                </p>
                <p class="text-base leading-8 text-base-content/75">
                  These Terms of Use are a legally binding agreement between you and
                  <strong class="text-base-content">SMPL LABS LLC</strong>
                  ("Company," "we,"
                  "us," or "our") concerning your access to and use of
                  <a
                    href="https://urielm.dev"
                    class="link link-primary font-semibold"
                  >
                    urielm.dev
                  </a>
                  and related products and services that link to these terms (collectively, the
                  "Services").
                </p>
                <p class="text-base leading-8 text-base-content/75">
                  By accessing the Services, you confirm that you have read, understood, and agreed
                  to these terms. If you do not agree, you must discontinue use of the Services.
                  Supplemental terms posted through the Services are incorporated by reference.
                </p>
                <p class="text-base leading-8 text-base-content/75">
                  We may update these terms by changing the date above. Your continued use after
                  revised terms are posted constitutes acceptance of those revisions. Please retain
                  a copy for your records and review our
                  <.link
                    navigate={~p"/privacy"}
                    class="link link-primary font-semibold"
                  >
                    Privacy Policy
                  </.link>
                  for details about personal information.
                </p>
              </div>
            </section>

            <.terms_section number={1} title="Our services">
              <p>
                The Services are operated from the United States. Information made available through
                the Services is not intended for distribution or use where doing so would violate law
                or subject us to a registration requirement. If you access the Services elsewhere,
                you do so on your own initiative and are responsible for complying with local law.
              </p>
            </.terms_section>

            <.terms_section number={2} title="Intellectual property rights">
              <h3 class="mt-3 text-lg font-bold text-base-content">Our intellectual property</h3>
              <p>
                We own or license the intellectual property in the Services, including source code,
                databases, functionality, software, designs, audio, video, text, photographs, and
                graphics (the "Content"), along with trademarks, service marks, and logos (the
                "Marks"). Content and Marks are protected by intellectual-property and unfair-
                competition laws and treaties.
              </p>
              <p>
                While you comply with these terms, we grant you a non-exclusive, non-transferable,
                revocable license to access the Services and download or print portions you may
                properly access, solely for personal, non-commercial use or an internal business
                purpose. No other right is granted. Commercial copying, republication, distribution,
                sale, licensing, translation, or exploitation requires our prior written permission.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">Submissions</h3>
              <p>
                If you directly send us feedback, ideas, suggestions, questions, or comments about
                the Services ("Submissions"), you assign to us the intellectual-property rights in
                those Submissions so we may use them for any lawful purpose without acknowledgment or
                compensation. You represent that you have the necessary rights to submit them, that
                they are not confidential, and that they do not violate law or another person's rights.
              </p>
            </.terms_section>

            <.terms_section number={3} title="User representations">
              <p>By using the Services, you represent and warrant that:</p>
              <ul class="list-disc space-y-2 pl-6 marker:text-primary">
                <li>you have legal capacity and agree to comply with these terms;</li>
                <li>you are not a minor where you reside;</li>
                <li>you will not access the Services through unauthorized automated means;</li>
                <li>you will not use the Services for an illegal or unauthorized purpose; and</li>
                <li>your use will comply with applicable law.</li>
              </ul>
              <p>
                If account information you provide is untrue, inaccurate, outdated, or incomplete,
                we may suspend or terminate the account and refuse current or future use.
              </p>
            </.terms_section>

            <.terms_section number={4} title="Prohibited activities">
              <p>You may use the Services only for their intended purposes. You agree not to:</p>
              <ul class="list-disc space-y-2 pl-6 marker:text-primary">
                <li>systematically scrape, harvest, or compile Service data without permission;</li>
                <li>
                  defraud or mislead users, obtain passwords, impersonate others, or create false accounts;
                </li>
                <li>bypass security, access controls, rate limits, or content protections;</li>
                <li>harass, threaten, abuse, discriminate against, or harm another person;</li>
                <li>submit false abuse reports or misuse support channels;</li>
                <li>upload malware, spam, tracking mechanisms, or other disruptive material;</li>
                <li>
                  interfere with the Services or impose an unreasonable burden on infrastructure;
                </li>
                <li>
                  remove proprietary notices or unlawfully copy, reverse engineer, or adapt software;
                </li>
                <li>
                  collect user information for unsolicited messages or unauthorized commercial use;
                </li>
                <li>use unauthorized bots, scripts, spiders, or extraction tools; or</li>
                <li>otherwise violate law, these terms, or another person's rights.</li>
              </ul>
            </.terms_section>

            <.terms_section number={5} title="User-generated contributions">
              <p>
                The Services may allow you to create, submit, post, display, transmit, publish, or
                distribute text, prompts, comments, messages, images, profile information, and other
                materials ("Contributions"). Contributions may be visible to other users or through
                third-party services.
              </p>
              <p>
                You represent that your Contributions do not infringe intellectual-property, privacy,
                publicity, or other rights; are not unlawful, deceptive, defamatory, obscene,
                threatening, discriminatory, or abusive; do not contain malware or unauthorized
                advertising; and comply with these terms. You are responsible for your Contributions.
              </p>
            </.terms_section>

            <.terms_section number={6} title="Contribution license">
              <p>
                You retain ownership of your Contributions. By making a Contribution available
                through the Services, you grant us a worldwide, non-exclusive, royalty-free license
                to host, store, reproduce, display, format, and distribute it only as reasonably
                necessary to operate, secure, improve, and provide the Services and their sharing
                features, subject to our Privacy Policy and your account choices.
              </p>
              <p>
                You may remove Contributions where the Services provide that capability. Copies may
                remain temporarily in backups or where retention is legally required. Feedback may
                be used and shared without compensation. We are not responsible for statements you
                make in your Contributions.
              </p>
            </.terms_section>

            <.terms_section number={7} title="Services management">
              <p>
                We may monitor the Services for violations, take appropriate legal action, report
                unlawful conduct, restrict or remove Contributions, disable files that burden our
                systems, and otherwise manage the Services to protect users, our rights and property,
                and reliable operation. We are not obligated to monitor every activity or Contribution.
              </p>
            </.terms_section>

            <.terms_section number={8} title="Term and termination">
              <p>
                These terms remain effective while you use the Services. To the fullest extent
                permitted by law, we may deny access, suspend or terminate accounts, block addresses,
                or remove content for a violation of these terms or applicable law, security or abuse
                concerns, or conduct that risks harm to the Services or others.
              </p>
              <p>
                After suspension or termination, you may not create another account to evade the
                restriction. Provisions that by their nature should survive termination remain in
                effect, and we may pursue available legal remedies.
              </p>
            </.terms_section>

            <.terms_section number={9} title="Modifications and interruptions">
              <p>
                We may change, update, suspend, or discontinue some or all of the Services without
                notice. Availability is not guaranteed; maintenance, technical failures, or other
                events may cause interruptions, delays, or errors. To the fullest extent permitted by
                law, we are not liable for loss or inconvenience caused by such changes or downtime.
              </p>
            </.terms_section>

            <.terms_section number={10} title="Governing law">
              <div id="terms-governing-law">
                <p>
                  These terms are governed by the laws of the State of Texas, without regard to its
                  conflict-of-law principles. Subject to Section 11 and any non-waivable rights under
                  applicable law, you and SMPL LABS LLC consent to the exclusive jurisdiction of the
                  state and federal courts serving Travis County, Texas.
                </p>
              </div>
            </.terms_section>

            <.terms_section number={11} title="Dispute resolution">
              <p>
                Before filing a lawsuit, each party agrees to make a good-faith effort to resolve a
                dispute informally. The party raising the dispute must provide written notice
                describing the issue and requested resolution, and the parties will attempt to resolve
                it for at least 30 days after notice is received.
              </p>
              <p>
                If informal negotiation does not resolve the dispute, either party may bring an
                individual claim in the courts identified in Section 10, except where applicable law
                permits another forum. Nothing prevents either party from seeking urgent injunctive
                relief or bringing claims involving intellectual property, privacy, theft, piracy, or
                unauthorized use. These terms do not require binding arbitration.
              </p>
            </.terms_section>

            <.terms_section number={12} title="Corrections">
              <p>
                Information in the Services may contain typographical errors, inaccuracies, or
                omissions, including descriptions, pricing, or availability. We may correct or update
                that information at any time without prior notice.
              </p>
            </.terms_section>

            <.terms_section number={13} title="Disclaimer">
              <p class="font-semibold text-base-content/80">
                THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE." TO THE FULLEST EXTENT
                PERMITTED BY LAW, WE DISCLAIM EXPRESS AND IMPLIED WARRANTIES, INCLUDING
                MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
              </p>
              <p>
                We do not warrant that the Services will be accurate, complete, uninterrupted,
                secure, or free of errors or harmful components. We are not responsible for third-
                party websites, content, products, or services linked or made available through the
                Services. Use appropriate judgment when interacting with third parties.
              </p>
            </.terms_section>

            <.terms_section number={14} title="Limitations of liability">
              <p class="font-semibold text-base-content/80">
                TO THE FULLEST EXTENT PERMITTED BY LAW, SMPL LABS LLC AND ITS DIRECTORS, EMPLOYEES,
                AND AGENTS WILL NOT BE LIABLE FOR INDIRECT, CONSEQUENTIAL, EXEMPLARY, INCIDENTAL,
                SPECIAL, OR PUNITIVE DAMAGES, INCLUDING LOST PROFITS, REVENUE, OR DATA, ARISING FROM
                YOUR USE OF THE SERVICES, EVEN IF ADVISED THAT SUCH DAMAGES WERE POSSIBLE.
              </p>
              <p>
                Our aggregate liability for claims relating to the Services will not exceed the amount
                you paid us for the Services during the 12 months before the event giving rise to the
                claim or US $100, whichever is greater. Some jurisdictions do not permit certain
                exclusions or limitations, so portions of this section may not apply to you.
              </p>
            </.terms_section>

            <.terms_section number={15} title="Indemnification">
              <p>
                To the extent permitted by law, you agree to defend, indemnify, and hold harmless
                SMPL LABS LLC, its affiliates, and their officers, agents, partners, and employees from
                third-party claims, losses, liabilities, and reasonable legal expenses arising from
                your use of the Services, breach of these terms, violation of another person's rights,
                or harmful conduct toward another user. We may assume control of a defense subject to
                indemnification, and you agree to cooperate reasonably.
              </p>
            </.terms_section>

            <.terms_section number={16} title="User data">
              <p>
                We maintain information you transmit and data relating to use of the Services to
                operate and manage them, as described in our <.link
                  navigate={~p"/privacy"}
                  class="link link-primary"
                >Privacy Policy</.link>.
                Although we use routine backup and security practices, you are responsible for keeping
                copies of Contributions that are important to you. No backup system can guarantee
                against every loss or corruption event.
              </p>
            </.terms_section>

            <.terms_section
              number={17}
              title="Electronic communications, transactions, and signatures"
            >
              <p>
                Visiting the Services, sending emails, and submitting online forms are electronic
                communications. You consent to receive agreements, notices, disclosures, and other
                communications electronically and agree that electronic delivery satisfies legal
                writing requirements where permitted. You agree to electronic signatures, contracts,
                records, and delivery for transactions initiated through the Services.
              </p>
            </.terms_section>

            <.terms_section number={18} title="Miscellaneous">
              <p>
                These terms and policies posted through the Services constitute the entire agreement
                regarding the Services. Failure to enforce a provision is not a waiver. We may assign
                our rights and obligations. We are not responsible for delay or failure caused by
                events beyond reasonable control. If a provision is unenforceable, it will be severed
                without affecting the remaining provisions. These terms create no partnership,
                employment, agency, or joint-venture relationship.
              </p>
            </.terms_section>

            <.terms_section number={19} title="Contact us">
              <p>
                To resolve a complaint or request more information about the Services or these terms,
                contact us at:
              </p>
              <address class="not-italic leading-8 text-base-content/70">
                <strong class="text-base-content">SMPL LABS LLC</strong>
                <br /> 5900 Balcones Drive, STE 100<br /> Austin, TX 78207<br /> United States
              </address>
              <p>
                Email:
                <a href="mailto:uriel@smpllabs.io" class="link link-primary font-semibold">
                  uriel@smpllabs.io
                </a>
              </p>
            </.terms_section>

            <footer class="px-3 py-6 text-center text-xs leading-6 text-base-content/45">
              These HTML terms are adapted from the SMPL LABS LLC Terms and Conditions document
              and updated to accurately describe Urielm's services.
            </footer>
          </main>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :number, :integer, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp terms_section(assigns) do
    ~H"""
    <section
      id={"terms-section-#{@number}"}
      class="card ui-card h-auto scroll-mt-24"
    >
      <div class="card-body gap-4 p-6 text-[0.95rem] leading-7 text-base-content/70 sm:p-8 sm:text-base sm:leading-8">
        <div class="flex items-start gap-3">
          <span class="badge badge-primary badge-outline mt-1 shrink-0 font-black">{@number}</span>
          <h2 class="text-xl font-black leading-tight tracking-tight text-base-content sm:text-2xl">
            {@title}
          </h2>
        </div>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end
end
