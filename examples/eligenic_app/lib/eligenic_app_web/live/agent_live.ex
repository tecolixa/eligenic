defmodule EligenicAppWeb.AgentLive do
  use EligenicAppWeb, :live_view
  require Logger

  # -----------------------------------------------------------------------------
  # 🏔️ Lifecycle: Mount & Initialization
  # -----------------------------------------------------------------------------

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Fetch localized agent configuration
      config = EligenicApp.EligenicConfig.agent_opts()

      # Simulate a persistent session ID (e.g., from a cookie or param)
      session_id = "default_user_session"

      # 1. Ensure a session exists (Persistence Layer)
      # 2. Resume or Start the agent process (Concurrency Layer)
      with {:ok, _session} <- Eligenic.init_session(session_id, config),
           {:ok, agent_pid, session} <- Eligenic.resume_session(session_id, config),
           {:ok, history} <- Eligenic.get_history(agent_pid) do
        {:ok,
         assign(socket,
           messages: history,
           input: "",
           status: :idle,
           status_text: "",
           agent: agent_pid,
           session_id: session.id,
           tools: Keyword.get(config, :tools) || Enum.flat_map(config[:skills], & &1.tools())
         ), layout: false}
      else
        {:error, reason} ->
          Logger.error("Failed to initialize session: #{inspect(reason)}")

          {:ok,
           assign(socket,
             messages: [],
             input: "",
             status: :error,
             status_text: "System Offline",
             agent: nil,
             tools: []
           ), layout: false}
      end
    else
      {:ok,
       assign(socket,
         messages: [],
         input: "",
         status: :idle,
         status_text: "",
         agent: nil,
         tools: []
       ), layout: false}
    end
  end

  # -----------------------------------------------------------------------------
  # 🎨 Rendering: UI View
  # -----------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 selection:bg-primary selection:text-primary-content relative overflow-hidden transition-colors duration-500 text-base-content">
      <!-- Ambient Background Effects -->
      <div class="absolute inset-0 z-0 opacity-30 pointer-events-none">
        <svg
          viewBox="0 0 1480 957"
          fill="none"
          class="absolute h-full w-full opacity-50 contrast-125 transition-all duration-1000"
          preserveAspectRatio="xMinYMid slice"
        >
          <path fill="var(--color-primary)" d="M0 0h1480v957H0z" class="opacity-5" />
          <path
            d="M137.542 466.27c-582.851-48.41-988.806-82.127-1608.412 658.2l67.39 810 3083.15-256.51L1535.94-49.622l-98.36 8.183C1269.29 281.468 734.115 515.799 146.47 467.012l-8.928-.742Z"
            fill="var(--color-primary)"
            class="opacity-10"
          />
          <path
            d="M371.028 528.664C-169.369 304.988-545.754 149.198-1361.45 665.565l-182.58 792.025 3014.73 694.98 389.42-1689.25-96.18-22.171C1505.28 697.438 924.153 757.586 379.305 532.09l-8.277-3.426Z"
            fill="var(--color-secondary)"
            class="opacity-10"
          />
        </svg>
      </div>

      <div class="max-w-7xl mx-auto p-4 md:p-10 grid grid-cols-1 lg:grid-cols-4 gap-8 relative z-10 h-screen max-h-[1000px]">
        <!-- Sidebar: Skills & Status -->
        <aside class="lg:col-span-1 space-y-8 h-full hidden lg:block overflow-y-auto pr-2 custom-scrollbar">
          <div class="card glass-premium overflow-hidden">
            <div class="bg-primary/10 p-5 border-b border-primary/20">
              <h2 class="font-black flex items-center gap-3 text-primary uppercase tracking-[0.2em] text-[10px]">
                <.icon name="hero-cpu-chip" class="w-5 h-5" /> Core Capabilities
              </h2>
            </div>
            <div class="p-5 space-y-4">
              <%= for tool <- @tools do %>
                <div class="group flex flex-col p-3 rounded-2xl bg-base-200/40 border border-transparent transition-all hover:bg-primary/5 hover:border-primary/30 cursor-default shadow-sm hover:shadow-md">
                  <span class="text-xs font-bold group-hover:text-primary transition-colors flex items-center justify-between">
                    <%= tool.function.name
                    |> String.split(".")
                    |> List.last()
                    |> String.replace("_", " ")
                    |> String.capitalize() %>
                    <.icon
                      name="hero-bolt"
                      class="w-4 h-4 text-primary opacity-0 group-hover:opacity-100 transition-all scale-75 group-hover:scale-100"
                    />
                  </span>
                  <span class="text-[9px] uppercase tracking-wider opacity-40 font-bold mt-1 truncate">
                    <%= tool.function.name %>
                  </span>
                </div>
              <% end %>
            </div>
          </div>

          <div class="card glass-premium overflow-hidden">
            <div class="bg-secondary/10 p-5 border-b border-secondary/20 flex justify-between items-center">
              <h2 class="font-black flex items-center gap-3 text-secondary uppercase tracking-[0.2em] text-[10px]">
                <.icon name="hero-cog-6-tooth" class="w-5 h-5" /> Environment
              </h2>
              <EligenicAppWeb.Layouts.theme_toggle />
            </div>
            <div class="p-5 space-y-5">
              <div class="flex justify-between items-center text-[10px] uppercase font-black">
                <span class="opacity-40">Process ID</span>
                <span class="text-secondary badge badge-ghost badge-sm font-mono tracking-tighter">
                  <%= inspect(self()) |> String.slice(5..-2//1) %>
                </span>
              </div>
              <div class="flex justify-between items-center text-[10px] uppercase font-black">
                <span class="opacity-40">LLM Node</span>
                <span class="text-base-content px-2 py-0.5 rounded bg-base-300">Gemini 1.5</span>
              </div>
              <div class="flex justify-between items-center text-[10px] uppercase font-black">
                <span class="opacity-40">Security</span>
                <span class="text-success flex items-center gap-1.5">
                  <div class="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></div>
                  Hardened
                </span>
              </div>
            </div>
          </div>
        </aside>

        <!-- Main Content: Chat -->
        <main class="lg:col-span-3 flex flex-col h-full lg:h-[850px] glass-premium rounded-[3rem] overflow-hidden shadow-2xl relative">
          <header class="p-6 md:p-8 border-b border-base-300/50 flex justify-between items-center bg-base-100/30 backdrop-blur-md sticky top-0 z-20">
            <div class="flex items-center gap-4 md:gap-6">
              <div class="relative group">
                <div class="absolute -inset-2 bg-primary rounded-2xl blur opacity-20 group-hover:opacity-40 transition animate-pulse">
                </div>
                <div class="relative bg-primary w-12 h-12 md:w-14 md:h-14 rounded-2xl flex items-center justify-center text-primary-content shadow-xl shadow-primary/20 rotate-3 group-hover:rotate-0 transition-transform duration-500">
                  <.icon name="hero-sparkles" class="w-7 h-7 md:w-8 md:h-8" />
                </div>
              </div>
              <div>
                <h1 class="text-xl md:text-2xl font-black tracking-tighter italic uppercase text-base-content">
                  Eligenic <span class="text-primary not-italic">OS</span>
                </h1>
                <div class="flex items-center gap-2 mt-0.5">
                  <span class="relative flex h-2 w-2">
                    <span class={["animate-ping absolute inline-flex h-full w-full rounded-full opacity-75", if(@status == :thinking, do: "bg-warning", else: "bg-success")]}>
                    </span>
                    <span class={["relative inline-flex rounded-full h-2 w-2", if(@status == :thinking, do: "bg-warning", else: "bg-success")]}>
                    </span>
                  </span>
                  <p class="text-[9px] md:text-[10px] uppercase tracking-[0.2em] opacity-50 font-black">
                    <%= if @status == :thinking, do: "Neural Synthesis Active", else: "Neural Interface Idle" %>
                  </p>
                </div>
              </div>
            </div>
            <div class="hidden sm:block">
              <span class="badge badge-outline border-base-300 opacity-40 text-[9px] font-black tracking-widest uppercase">
                v0.1.0-PROTOTYPE
              </span>
            </div>
          </header>

          <div
            id="chat-scroll-area"
            phx-hook="ChatMessages"
            class="flex-1 p-6 md:p-12 overflow-y-auto space-y-8 scroll-smooth custom-scrollbar"
          >
            <%= if Enum.empty?(@messages) do %>
              <div
                id="empty-state"
                class="flex flex-col items-center justify-center h-full text-base-content/20 space-y-8 py-20"
              >
                <div class="relative w-32 h-32 md:w-40 md:h-40 opacity-10">
                  <div class="absolute inset-0 bg-primary/20 rounded-full blur-3xl animate-pulse"></div>
                  <svg viewBox="0 0 100 100" class="relative fill-current drop-shadow-2xl">
                    <path d="M50 10L10 90L90 90L50 10Z" />
                  </svg>
                </div>
                <div class="text-center space-y-3">
                  <h3 class="font-black tracking-[0.4em] uppercase text-sm">System Standby</h3>
                  <p class="text-[11px] opacity-60 font-medium max-w-[250px] mx-auto leading-relaxed">
                    Ready to process multi-modal requests and execute capability-driven skills.
                  </p>
                </div>
              </div>
            <% end %>

            <div id="chat-messages" class="space-y-10 pb-4">
              <%= for {msg, idx} <- Enum.with_index(@messages) do %>
                <div
                  id={"msg-#{idx}"}
                  class={[
                    "chat",
                    if(msg.role == "user", do: "chat-end", else: "chat-start"),
                    "group transition-all duration-500 hover:translate-y-[-2px]"
                  ]}
                >
                  <div class="chat-image avatar mt-1">
                    <div class={[
                      "w-10 h-10 md:w-11 md:h-11 rounded-2xl p-2 md:p-2.5 border-2 transition-transform group-hover:rotate-6",
                      if(msg.role == "user",
                        do: "bg-primary text-primary-content border-primary shadow-lg shadow-primary/20",
                        else: "bg-base-300 text-secondary border-secondary/20 shadow-md"
                      )
                    ]}>
                      <%= if msg.role == "user" do %>
                        <.icon name="hero-user" class="w-full h-full" />
                      <% else %>
                        <.icon name="hero-academic-cap" class="w-full h-full" />
                      <% end %>
                    </div>
                  </div>
                  <div class={[
                    "chat-bubble flex flex-col gap-2 min-h-[44px] shadow-2xl max-w-[90%] md:max-w-[85%] text-[14px] md:text-[15px] leading-relaxed p-4 px-6 relative",
                    if(msg.role == "user",
                      do:
                        "bg-gradient-to-br from-primary via-primary to-primary/80 text-primary-content rounded-3xl rounded-tr-none border-primary/20",
                      else:
                        "bg-base-200 text-base-content font-medium rounded-3xl rounded-tl-none border border-base-300/50 backdrop-blur-sm shadow-inner"
                    )
                  ]}>
                    <div class="whitespace-pre-wrap"><%= msg.content %></div>
                    <span class="text-[9px] opacity-30 font-black uppercase tracking-widest mt-1">
                      <%= if msg.role == "user", do: "Transmitted", else: "Generated" %>
                    </span>
                  </div>
                </div>
              <% end %>

              <%= if @status == :thinking do %>
                <div id="thinking-indicator" class="chat chat-start">
                  <div class="chat-image avatar mt-1 opacity-50">
                    <div class="w-10 h-10 rounded-2xl p-2 bg-base-300 text-secondary border-2 border-secondary/20 animate-pulse">
                      <.icon name="hero-sparkles" class="w-full h-full" />
                    </div>
                  </div>
                  <div class="flex items-center gap-4 bg-base-200/50 backdrop-blur-md p-4 px-6 rounded-3xl rounded-tl-none border border-secondary/20 shadow-lg">
                    <div class="flex gap-1.5">
                      <div class="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce [animation-delay:-0.3s]">
                      </div>
                      <div class="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce [animation-delay:-0.15s]">
                      </div>
                      <div class="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce"></div>
                    </div>
                    <span class="text-[10px] uppercase font-black tracking-[0.2em] text-secondary">
                      <%= @status_text %>
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <footer class="p-6 md:p-10 bg-base-200/40 border-t border-base-300/50 backdrop-blur-xl">
            <form phx-submit="send_message" class="relative max-w-4xl mx-auto group">
              <!-- Glow Effect -->
              <div class="absolute -inset-1 bg-gradient-to-r from-primary/30 to-secondary/30 rounded-[2.5rem] blur-xl opacity-0 group-focus-within:opacity-100 transition duration-1000">
              </div>

              <div class="relative flex items-center">
                <input
                  type="text"
                  name="message"
                  value={@input}
                  placeholder="Input command sequence..."
                  class="input input-lg w-full h-14 md:h-16 pr-16 md:pr-20 pl-6 md:pl-8 bg-base-100/80 border-2 border-base-300/50 focus:border-primary focus:ring-8 focus:ring-primary/5 transition-all rounded-[2rem] text-[15px] md:text-[16px] font-medium placeholder:opacity-30 placeholder:italic"
                  autofocus
                  autocomplete="off"
                  disabled={@status == :thinking}
                />
                <button
                  type="submit"
                  class="btn btn-primary h-10 w-10 md:h-12 md:w-12 min-h-0 absolute right-2 md:right-3 rounded-2xl shadow-xl shadow-primary/30 hover:scale-105 active:scale-95 transition-all disabled:opacity-50"
                  disabled={@status == :thinking or @input == "..."}
                >
                  <%= if @status == :thinking do %>
                    <span class="loading loading-spinner loading-sm"></span>
                  <% else %>
                    <.icon name="hero-arrow-up" class="w-5 h-5 md:w-6 md:h-6 stroke-2" />
                  <% end %>
                </button>
              </div>
            </form>

            <div class="mt-6 md:mt-8 flex flex-wrap gap-3 md:gap-4 justify-center">
              <button
                phx-click="fill_and_send"
                phx-value-text="Store a note about Eligenic: Eligenic is a modular AI agent framework for Elixir."
                class="group flex items-center gap-2 px-4 md:px-6 py-2 rounded-full bg-primary/10 hover:bg-primary transition-all duration-300 border border-primary/20"
                disabled={@status == :thinking}
              >
                <.icon name="hero-document-plus" class="w-4 h-4 text-primary group-hover:text-primary-content transition-colors" />
                <span class="text-[10px] md:text-[11px] font-black uppercase tracking-widest text-primary group-hover:text-primary-content transition-colors">
                  Store Note
                </span>
              </button>
              <button
                phx-click="fill_and_send"
                phx-value-text="Search the knowledge base for 'Eligenic'"
                class="group flex items-center gap-2 px-4 md:px-6 py-2 rounded-full bg-secondary/10 hover:bg-secondary transition-all duration-300 border border-secondary/20"
                disabled={@status == :thinking}
              >
                <.icon name="hero-magnifying-glass" class="w-4 h-4 text-secondary group-hover:text-secondary-content transition-colors" />
                <span class="text-[10px] md:text-[11px] font-black uppercase tracking-widest text-secondary group-hover:text-secondary-content transition-colors">
                  Search Knowledge
                </span>
              </button>
            </div>
          </footer>
        </main>
      </div>
    </div>
    """
  end

  # -----------------------------------------------------------------------------
  # 📥 Event Handling: User Interaction
  # -----------------------------------------------------------------------------

  @impl true
  def handle_event("fill_and_send", %{"text" => text}, socket) do
    send_message(text, socket)
  end

  @impl true
  def handle_event("send_message", %{"message" => text}, socket) do
    send_message(text, socket)
  end

  defp send_message(text, socket) do
    if String.trim(text) == "" do
      {:noreply, socket}
    else
      # 1. Immediate UI update: Show user message and set thinking status
      new_messages = socket.assigns.messages ++ [%{role: "user", content: text}]

      parent = self()
      agent_pid = socket.assigns.agent

      # 2. Async Execution: Offload Gemini call to background
      Task.start_link(fn ->
        # Smooth status progression
        send(parent, {:status_update, "Synthesizing Request..."})
        Process.sleep(800)
        send(parent, {:status_update, "Consulting Knowledge Graph..."})
        Process.sleep(800)
        send(parent, {:status_update, "Neural Pattern Matching..."})

        result = Eligenic.call(agent_pid, text)
        send(parent, {:agent_response, result})
      end)

      {:noreply,
       assign(socket,
         messages: new_messages,
         input: "",
         status: :thinking,
         status_text: "Initializing Reasoner..."
       )}
    end
  end

  # -----------------------------------------------------------------------------
  # 📟 Async Handlers: System Updates
  # -----------------------------------------------------------------------------

  @impl true
  def handle_info({:status_update, text}, socket) do
    {:noreply, assign(socket, status_text: text)}
  end

  @impl true
  def handle_info({:agent_response, {:ok, response}}, socket) do
    new_messages = socket.assigns.messages ++ [%{role: "assistant", content: response}]
    {:noreply, assign(socket, messages: new_messages, status: :idle)}
  end

  @impl true
  def handle_info({:agent_response, {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Agent Node Error: \#{inspect(_reason)}")
     |> assign(status: :idle)}
  end
end
