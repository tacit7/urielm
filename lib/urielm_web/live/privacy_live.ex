defmodule UrielmWeb.PrivacyLive do
  use UrielmWeb, :live_view

  @sections [
    {1, "What information do we collect?"},
    {2, "How do we process your information?"},
    {3, "What legal bases do we rely on?"},
    {4, "When and with whom do we share information?"},
    {5, "Cookies and tracking technologies"},
    {6, "Google and social logins"},
    {7, "How long do we keep your information?"},
    {8, "How do we keep your information safe?"},
    {9, "Information from minors"},
    {10, "Your privacy rights"},
    {11, "Do-Not-Track controls"},
    {12, "US residents' privacy rights"},
    {13, "Updates to this notice"},
    {14, "Contact us"},
    {15, "Review, update, or delete your data"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Privacy Policy")
     |> assign(
       :meta_description,
       "Learn how SMPL LABS LLC and urielm.dev collect, use, store, and protect personal information, including Google OAuth data."
     )
     |> assign(:canonical_url, "https://urielm.dev/privacy")
     |> assign(:sections, @sections)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="privacy"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="privacy-policy-page" class="min-h-screen bg-base-100">
        <header class="relative overflow-hidden border-b border-base-300/70">
          <div class="absolute inset-0 bg-[radial-gradient(circle_at_top,color-mix(in_oklab,var(--color-primary)_14%,transparent),transparent_58%)]">
          </div>
          <div class="relative mx-auto max-w-5xl px-5 py-16 text-center sm:px-7 sm:py-22 lg:px-8">
            <p class="mb-3 text-xs font-black uppercase tracking-[0.2em] text-primary">
              SMPL LABS LLC
            </p>
            <h1
              id="privacy-policy-title"
              class="text-4xl font-black tracking-[-0.045em] text-base-content sm:text-6xl"
            >
              Privacy Policy
            </h1>
            <p id="privacy-policy-updated" class="mt-4 text-sm text-base-content/60 sm:text-base">
              Last updated August 25, 2026
            </p>
          </div>
        </header>

        <div class="mx-auto grid max-w-6xl gap-8 px-5 py-10 sm:px-7 lg:grid-cols-[16rem_minmax(0,48rem)] lg:justify-center lg:px-8 lg:py-14">
          <aside class="lg:sticky lg:top-24 lg:self-start">
            <nav
              id="privacy-table-of-contents"
              aria-label="Privacy policy sections"
              class="card border border-base-300/80 bg-base-200/70 shadow-sm"
            >
              <div class="card-body gap-1 p-5">
                <h2 class="mb-2 text-sm font-black text-base-content">On this page</h2>
                <%= for {number, title} <- @sections do %>
                  <a
                    href={"#privacy-section-#{number}"}
                    class="rounded-lg px-2 py-1.5 text-xs leading-snug text-base-content/60 transition-colors hover:bg-primary/8 hover:text-primary focus-visible:outline-2 focus-visible:outline-primary"
                  >
                    <span class="font-bold text-base-content/80">{number}.</span> {title}
                  </a>
                <% end %>
              </div>
            </nav>
          </aside>

          <main class="min-w-0 space-y-5">
            <section class="card border border-primary/20 bg-primary/6 shadow-sm">
              <div class="card-body gap-4 p-6 sm:p-8">
                <p class="text-xs font-black uppercase tracking-[0.16em] text-primary">Notice</p>
                <p class="text-base leading-8 text-base-content/75">
                  This Privacy Notice for <strong class="text-base-content">SMPL LABS LLC</strong>
                  ("we," "us," or "our") describes how and why we may access, collect, store,
                  use, and share your personal information when you visit or use <a
                    href="https://urielm.dev"
                    class="link link-primary font-semibold"
                  >urielm.dev</a>,
                  create an account, or otherwise interact with our services.
                </p>
                <p class="text-base leading-8 text-base-content/75">
                  If you do not agree with this notice, please do not use our services. Questions
                  may be sent to <a
                    href="mailto:uriel@smpllabs.io"
                    class="link link-primary font-semibold"
                  >
                    uriel@smpllabs.io
                  </a>.
                </p>
              </div>
            </section>

            <section id="privacy-summary" class="card border border-base-300/80 bg-base-200 shadow-sm">
              <div class="card-body gap-5 p-6 sm:p-8">
                <div>
                  <p class="text-xs font-black uppercase tracking-[0.16em] text-primary">
                    At a glance
                  </p>
                  <h2 class="mt-2 text-2xl font-black tracking-tight text-base-content">
                    Summary of key points
                  </h2>
                </div>
                <div class="grid gap-4 sm:grid-cols-2">
                  <.summary_item title="Information we process">
                    Information you provide, account details, service activity, and limited profile
                    information received when you choose Google sign-in.
                  </.summary_item>
                  <.summary_item title="Sensitive information">
                    We do not intentionally process sensitive personal information.
                  </.summary_item>
                  <.summary_item title="How we use information">
                    To provide and secure the service, authenticate accounts, communicate with you,
                    prevent fraud, and comply with law.
                  </.summary_item>
                  <.summary_item title="Your choices">
                    You may review, correct, or request deletion of your account information as
                    described below.
                  </.summary_item>
                </div>
              </div>
            </section>

            <.policy_section number={1} title="What information do we collect?">
              <h3 class="mt-3 text-lg font-bold text-base-content">
                Personal information you disclose to us
              </h3>
              <p>
                We collect personal information you voluntarily provide when you register, express
                interest in our services, participate in activities on the service, or contact us.
                Depending on your interactions and the features you use, this may include:
              </p>
              <ul class="list-disc space-y-2 pl-6 marker:text-primary">
                <li>name and email address;</li>
                <li>username, password hash, and account preferences;</li>
                <li>profile image, job title, or other profile details you choose to provide;</li>
                <li>billing address if a paid service requires it; and</li>
                <li>content, messages, prompts, comments, and other information you submit.</li>
              </ul>
              <p>
                We do not intentionally process sensitive personal information. Information you
                provide must be true, complete, and accurate, and you should notify us of changes.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">
                Information received from Google
              </h3>
              <p>
                If you choose Google sign-in, we receive limited account and profile information
                from Google as described in Section 6. We do not receive your Google password.
              </p>
            </.policy_section>

            <.policy_section number={2} title="How do we process your information?">
              <p>
                We process personal information to provide, improve, and administer our services,
                communicate with you, protect the service, prevent fraud, and comply with law. In
                particular, we may process information to:
              </p>
              <ul class="list-disc space-y-2 pl-6 marker:text-primary">
                <li>create, authenticate, link, and maintain user accounts;</li>
                <li>provide requested features and preserve account preferences;</li>
                <li>respond to support, privacy, and service requests;</li>
                <li>detect abuse, security incidents, and fraudulent activity;</li>
                <li>improve reliability and understand how the service is used; and</li>
                <li>protect an individual's vital interests or comply with legal obligations.</li>
              </ul>
              <p>
                We process information only when we have a valid legal reason and may process it for
                other purposes with your prior consent.
              </p>
            </.policy_section>

            <.policy_section
              number={3}
              title="What legal bases do we rely on to process your personal information?"
            >
              <p>
                We process personal information when we believe it is necessary and have a valid
                legal basis, including consent, performance of a contract, compliance with law,
                protection of rights or vital interests, and legitimate business interests.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">
                European Economic Area and United Kingdom
              </h3>
              <p>
                If you are in the EEA or UK, we may rely on your consent, our contractual obligations,
                legal obligations, legitimate interests that do not override your rights, or the need
                to protect vital interests. You may withdraw consent at any time, without affecting
                processing that was lawful before withdrawal.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">Canada</h3>
              <p>
                If you are in Canada, we may process information with express or implied consent. In
                limited circumstances, applicable law may permit processing without consent, such as
                emergencies, fraud investigations, certain business transactions, legal process,
                insurance claims, identifying injured or deceased persons, preventing financial
                abuse, journalistic or artistic purposes, or use of publicly available information.
              </p>
              <p>
                We may disclose de-identified information for approved research or statistical
                projects subject to appropriate oversight and confidentiality commitments.
              </p>
            </.policy_section>

            <.policy_section
              number={4}
              title="When and with whom do we share your personal information?"
            >
              <p>
                We may share information in limited situations with service providers that help us
                operate, host, secure, or support the service, subject to appropriate contractual
                protections. We may also share or transfer information during negotiations for, or
                completion of, a merger, sale of assets, financing, acquisition, or similar business
                transaction.
              </p>
              <p>
                We may disclose information when required by law, legal process, or a valid government
                request, or when reasonably necessary to protect users, our rights, or public safety.
                We do not sell personal information.
              </p>
            </.policy_section>

            <.policy_section number={5} title="Do we use cookies and other tracking technologies?">
              <p>
                We may use cookies and similar technologies to maintain sessions, protect accounts,
                prevent crashes, fix bugs, save preferences, and provide basic site functionality.
                Your browser generally lets you remove or reject cookies, although doing so may affect
                parts of the service.
              </p>
              <p>
                If analytics or advertising technologies are used, applicable law may treat some
                activity as a sale or sharing for targeted advertising. Where required, you may opt
                out by contacting us or using available account and browser controls.
              </p>
            </.policy_section>

            <.policy_section number={6} title="How do we handle Google and other social logins?">
              <div
                id="google-oauth-disclosure"
                class="mb-6 rounded-2xl border border-primary/20 bg-primary/6 p-5 sm:p-6"
              >
                <p class="text-xs font-black uppercase tracking-[0.16em] text-primary">
                  Google OAuth disclosure
                </p>
                <h3 class="mt-2 text-xl font-black tracking-tight text-base-content">
                  Data used for Google sign-in
                </h3>
                <p class="mt-3 leading-7 text-base-content/70">
                  Urielm requests Google's <strong class="text-base-content">email</strong>
                  and <strong class="text-base-content">profile</strong>
                  scopes. Google may provide your
                  Google account identifier, name, email address, and profile image. We use this data
                  only to create your Urielm account, authenticate sign-in, link your Google identity,
                  support account security, and display the profile information you authorize.
                </p>
                <p class="mt-3 leading-7 text-base-content/70">
                  We store the account information, provider identifier, OAuth credential returned
                  during sign-in, and returned profile information with your Urielm account. We do not
                  use this information to access unrelated Google services, build advertising
                  profiles, or sell Google user data. We share it only with infrastructure providers
                  necessary to operate and secure Urielm, or when legally required.
                </p>
                <p class="mt-3 leading-7 text-base-content/70">
                  Urielm's use and transfer of information received from Google APIs adheres to the <a
                    href="https://developers.google.com/terms/api-services-user-data-policy"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="link link-primary font-semibold"
                  >
                    Google API Services User Data Policy
                  </a>, including its Limited Use requirements.
                </p>
              </div>
              <p>
                If we offer another third-party login, the information received varies by provider
                and your settings but may include your name, email address, account identifier, and
                profile image. We use it only for the purposes described in this notice or otherwise
                disclosed when you use the feature.
              </p>
              <p>
                Third-party providers control their own processing. Review the provider's privacy
                notice and account controls to understand how it handles your information.
              </p>
            </.policy_section>

            <.policy_section number={7} title="How long do we keep your information?">
              <p>
                We retain personal information only as long as necessary for the purposes described
                in this notice, including while you maintain an account, unless law permits or requires
                a longer period for tax, accounting, security, dispute resolution, or other legal
                reasons.
              </p>
              <p>
                When we no longer have a legitimate business need, we delete or anonymize information.
                If immediate deletion is not possible, such as in backup archives, we securely isolate
                the information from further processing until deletion is possible.
              </p>
            </.policy_section>

            <.policy_section number={8} title="How do we keep your information safe?">
              <p>
                We use reasonable technical and organizational safeguards designed to protect personal
                information. No transmission or storage technology is completely secure, so we cannot
                guarantee that unauthorized parties will never defeat those safeguards. Use the
                service only in a secure environment and protect your account credentials.
              </p>
            </.policy_section>

            <.policy_section number={9} title="Do we collect information from minors?">
              <p>
                We do not knowingly collect data from or market to children under 18, or the equivalent
                minimum age in the user's jurisdiction. By using the service, you represent that you
                meet this requirement or are the parent or guardian of a minor whose use you authorize.
              </p>
              <p>
                If we learn that we collected information from a child contrary to this policy, we
                will deactivate the account and take reasonable steps to delete the information.
                Contact
                <a href="mailto:uriel@smpllabs.io" class="link link-primary">uriel@smpllabs.io</a>
                if you believe this has occurred.
              </p>
            </.policy_section>

            <.policy_section number={10} title="What are your privacy rights?">
              <p>
                Depending on your location, you may have rights to access, correct, erase, restrict,
                or object to processing; receive a portable copy of information; withdraw consent; and
                avoid decisions based solely on automated processing that produce significant effects.
                These rights may be limited by applicable law.
              </p>
              <p>
                Submit a request through your account settings or email <a
                  href="mailto:uriel@smpllabs.io"
                  class="link link-primary"
                >uriel@smpllabs.io</a>.
                We will consider requests under applicable law and may need to verify your identity.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">EEA, UK, and Switzerland</h3>
              <p>
                You may complain to your local data protection authority. UK residents may contact the
                Information Commissioner's Office through <a
                  href="https://ico.org.uk/make-a-complaint"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="link link-primary"
                >
                  ico.org.uk/make-a-complaint
                </a>. Swiss residents may contact the Federal Data Protection and Information
                Commissioner.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">
                Marketing, account, and cookie choices
              </h3>
              <p>
                You may unsubscribe from marketing through the link in a message or by contacting us.
                We may still send necessary service communications. You may update or terminate your
                account through account settings. Browser controls can remove or reject cookies, but
                this may affect service functionality.
              </p>
            </.policy_section>

            <.policy_section number={11} title="Controls for Do-Not-Track features">
              <p>
                Some browsers and operating systems offer a Do-Not-Track signal. Because no uniform
                technical standard for recognizing and implementing these signals has been finalized,
                we do not currently respond to them. If a standard we must follow is adopted, we will
                update this notice. California law requires this disclosure.
              </p>
            </.policy_section>

            <.policy_section
              number={12}
              title="Do United States residents have specific privacy rights?"
            >
              <p>
                Residents of states with comprehensive privacy laws may have rights to know whether we
                process personal data, access it, correct inaccuracies, request deletion, obtain a
                copy, and exercise rights without discrimination. Depending on the state, you may also
                opt out of targeted advertising, sale or sharing, or profiling with significant effects.
              </p>

              <div class="overflow-x-auto rounded-2xl border border-base-300/80">
                <table class="table table-sm" aria-label="Categories of personal information">
                  <thead>
                    <tr>
                      <th>Category</th>
                      <th>Examples</th>
                      <th>Collected</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="font-semibold">Identifiers</td>
                      <td>Name, email, username, online or provider identifier</td>
                      <td>Yes, as described in Section 1</td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Account and profile information</td>
                      <td>Profile image, preferences, content, and service interactions</td>
                      <td>Yes, when provided or generated through use</td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Sensitive information</td>
                      <td>Protected characteristics, precise location, biometrics</td>
                      <td>No</td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Commercial information</td>
                      <td>Transaction and purchase details</td>
                      <td>Only if required by a paid service</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <h3 class="mt-3 text-lg font-bold text-base-content">Additional state rights</h3>
              <p>
                Depending on state law, you may request categories or specific third parties receiving
                personal data; question or correct profiling; limit sensitive-data use; or opt out of
                voice or facial recognition collection. We do not sell personal information and have
                not sold personal information in the preceding 12 months.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">Requests, agents, and appeals</h3>
              <p>
                Email us to exercise your rights. We may verify your identity and an authorized agent's
                authority. If we decline a request, residents of states providing an appeal right may
                appeal by emailing us. If an appeal is denied, you may contact your state attorney
                general.
              </p>
              <h3 class="mt-3 text-lg font-bold text-base-content">California Shine the Light</h3>
              <p>
                California Civil Code Section 1798.83 permits California residents to request certain
                information about disclosures for direct-marketing purposes once per year, free of
                charge. Submit any such written request using the contact details in Section 14.
              </p>
            </.policy_section>

            <.policy_section number={13} title="Do we make updates to this notice?">
              <p>
                We may update this notice as necessary to remain compliant and reflect our practices.
                The revised version will display an updated date. For material changes, we may post a
                prominent notice or contact you directly. Review this page periodically.
              </p>
            </.policy_section>

            <.policy_section number={14} title="How can you contact us about this notice?">
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
            </.policy_section>

            <.policy_section
              number={15}
              title="How can you review, update, or delete the data we collect from you?"
            >
              <p>
                Depending on applicable law, you may review or update account information through <.link
                  navigate={~p"/settings"}
                  class="link link-primary"
                >account settings</.link>.
                To request access, correction, account deletion, or deletion of Google OAuth data,
                email <a href="mailto:uriel@smpllabs.io" class="link link-primary">uriel@smpllabs.io</a>.
                We may retain limited information when required for legal, security, fraud-prevention,
                or backup purposes.
              </p>
            </.policy_section>

            <footer class="px-3 py-6 text-center text-xs leading-6 text-base-content/45">
              This HTML notice is adapted from the SMPL LABS LLC privacy policy and updated to
              describe Urielm's Google OAuth practices.
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

  defp policy_section(assigns) do
    ~H"""
    <section
      id={"privacy-section-#{@number}"}
      class="card scroll-mt-24 border border-base-300/80 bg-base-200 shadow-sm"
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

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp summary_item(assigns) do
    ~H"""
    <div class="rounded-2xl bg-base-100/70 p-4">
      <h3 class="font-bold text-base-content">{@title}</h3>
      <p class="mt-1 text-sm leading-6 text-base-content/65">{render_slot(@inner_block)}</p>
    </div>
    """
  end
end
