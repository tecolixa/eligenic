# Using Eligenic

Eligenic provides the `Eligenic.Agent` behavior. Because it is a `GenServer` under the hood, integrating Eligenic into an Elixir application revolves around defining its configuration struct and placing it into your application's supervision tree.

---

## 1. Basic Local Integration

The fastest way to use Eligenic is to instantiate an Agent with the default dependencies (`Eligenic.Memory.ETS` and `Eligenic.Runtime.Local`).

```elixir
# lib/my_app/my_agent.ex
defmodule MyApp.MyAgent do
  def start_link(_opts) do
    # 1. Define Identity
    identity = %Eligenic.Identity{
      id: "bot_01",
      persona: "You are a helpful customer support agent."
    }

    # 2. Start the Agent Process
    Eligenic.Agent.start_link(
      identity: identity,
      skills: [MyApp.Skills.CustomerSupport]
    )
  end
end
```

Then, you can add this module directly to your application tree:
```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    {MyApp.MyAgent, []}
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

---

## 2. Invoking the Agent

Once the Agent process is alive in your system, any part of your application (like a Phoenix Controller or LiveView) can asynchronously chat with it.

```elixir
iex> Eligenic.Agent.call("bot_01", "Can you check ticket #123?")
{:ok, "I found the ticket. It was created yesterday and the status is Open."}
```

Behind the scenes:
1. The Agent receives the user message.
2. It pushes the LLM reasoning to the `Eligenic.Runtime.Local` (PartitionSupervisor worker pool).
3. The Runtime parses the generated tool calls.
4. The `Eligenic.Executor` invokes `MyApp.Skills.CustomerSupport.check_ticket(123)`.
5. The result is returned to the user.

---

## 3. Advanced Pattern: Clustered Distribution (Horde)

By design, **Eligenic remains completely dependency-light.** It does not force heavy clustering libraries into your `mix.exs`. 

However, its native OTP architecture allows you to trivially wire them in yourself! If you want to dynamically distribute 10,000 Agents across a multi-node Kubernetes cluster, you can use `Horde`.

### Step A: Add Horde
In your application's `mix.exs`:
```elixir
def deps do
  [
    {:eligenic, "~> 0.1"},
    {:horde, "~> 0.9.0"}
  ]
end
```

### Step B: The Application Tree
In a distributed Kubernetes environment, you need two things to scale horizontally:
1. A global Registry so Node A knows if Node B is currently hosting "bot_01".
2. A Dynamic Supervisor to distribute the agent processes themselves.
3. A Task Supervisor to distribute the reasoning calculations natively.

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    # 1. Global registry for Agent Network Identifiers
    {Horde.Registry, name: MyApp.HordeRegistry, keys: :unique},
    
    # 2. Global supervisor to load-balance physical Agent processes
    {Horde.DynamicSupervisor, name: MyApp.HordeAgentSupervisor, strategy: :one_for_one},
    
    # 3. Global pool to load-balance async reasoning loops
    {Horde.TaskSupervisor, name: MyApp.HordeTaskSupervisor, strategy: :one_for_one}
  ]
  Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
end
```

### Step C: Write a Custom Runtime
Create an integration module in your application that implements `Eligenic.Runtime`.

```elixir
# lib/my_app/eligenic_horde_runtime.ex
defmodule MyApp.EligenicHordeRuntime do
  @behaviour Eligenic.Runtime

  @impl true
  def spawn_reasoning_loop(logic_callback) do
    # Tell Horde to execute this LLM call on the least loaded Node in the cluster!
    Horde.TaskSupervisor.async_nolink(
      MyApp.HordeTaskSupervisor,
      logic_callback
    )
  end
end
```

### Step D: Fire Up the Agents!
When you start your agents, you dictate where they live and how they compute using standard Elixir `:via` tuples for the registry, and the `:runtime` option for the architecture.

```elixir
# 1. Define global identity
agent_id = "distributed_bot_01"
global_name = {:via, Horde.Registry, {MyApp.HordeRegistry, agent_id}}

# 2. Start the Agent on the least-loaded Kubernetes Node
Horde.DynamicSupervisor.start_child(
  MyApp.HordeAgentSupervisor,
  {Eligenic.Agent, [
    name: global_name,
    identity: my_identity,
    skills: [MyApp.Skills.HeavyDataProcessing],
    runtime: MyApp.EligenicHordeRuntime
  ]}
)
```

And just like that, both the physical Agent `GenServer` memory footprint AND its heavy LLM task reasoning math are seamlessly load-balanced across your entire distributed Cloud Architecture. If a Kubernetes pod dies, `Horde.DynamicSupervisor` will simply restart the Eligenic Agent on a healthy node, while `Eligenic.Memory` recovers its conversation state.

---

## 4. Overriding Other Core Behaviors

Just like the `Runtime`, Eligenic allows you to securely swap other internal layers by implementing their `@behaviour` modules in your project:

### Database Memory
By default, conversation history uses `ETS`. For persistent postgres memory:
1. Implement `Eligenic.Memory` using Ecto.
2. Pass `memory: MyApp.EctoMemory`.

### Security Authorization
1. Implement `Eligenic.Security`.
2. Connect it to your app's `Bodyguard` or Guardian system inside `authorize/3`. 
3. Pass `security: MyApp.AuthSystem`.
