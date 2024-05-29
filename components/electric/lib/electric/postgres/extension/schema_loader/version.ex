defmodule Electric.Postgres.Extension.SchemaLoader.Version do
  alias Electric.Postgres.Schema
  alias Electric.Postgres.Extension.SchemaLoader
  alias Electric.Postgres.Schema.Proto.Table
  alias Electric.Postgres.Schema.FkGraph

  defstruct [:version, :schema, :fk_graph, tables: %{}, primary_keys: %{}]

  @type version() :: SchemaLoader.version()
  @type relation() :: SchemaLoader.relation()
  @type name() :: SchemaLoader.name()
  @type schema() :: SchemaLoader.schema()
  @type table_ref() :: relation() | %Table{} | %Schema.Proto.RangeVar{}

  @type t() :: %__MODULE__{
          version: nil | version(),
          schema: Schema.t(),
          fk_graph: FkGraph.t(),
          tables: %{relation() => %Table{}},
          primary_keys: %{relation() => [String.t()]}
        }

  @spec new(version() | nil, Schema.t()) :: t()
  def new(version, %Schema.Proto.Schema{} = schema) do
    %__MODULE__{version: version, schema: schema}
    |> Map.update!(:tables, &cache_tables_by_name(&1, schema))
    |> Map.update!(:primary_keys, &cache_pks_by_name(&1, schema))
    |> Map.put(:fk_graph, FkGraph.for_schema(schema))
  end

  defp cache_tables_by_name(tables, schema) do
    Enum.reduce(schema.tables, tables, fn table, cache ->
      Map.put(cache, table_name(table), table)
    end)
  end

  defp cache_pks_by_name(pks, schema) do
    Enum.reduce(schema.tables, pks, fn table, cache ->
      case Schema.primary_keys(table) do
        {:ok, pks} ->
          Map.put(cache, table_name(table), pks)

        {:error, _} ->
          Map.put(cache, table_name(table), [])
      end
    end)
  end

  defp table_name(%{name: %{schema: s, name: n}}) do
    {s, n}
  end

  defp table_name(%{schema: s, name: n}) do
    {s, n}
  end

  defp table_name({s, n}) do
    {s, n}
  end

  @spec tables(t()) :: [%Table{}]
  def tables(%__MODULE__{schema: schema}) do
    schema.tables
  end

  @spec table(t(), schema(), name()) :: {:ok, %Table{}} | {:error, String.t()}
  def table(%__MODULE__{tables: tables}, sname, tname) do
    fetch_table_value(tables, {sname, tname})
  end

  @spec table(t(), table_ref()) :: {:ok, %Table{}} | {:error, String.t()}
  def table(%__MODULE__{tables: tables}, name) do
    fetch_table_value(tables, table_name(name))
  end

  @spec table!(t(), table_ref()) :: %Table{} | no_return()
  def table!(version, name) do
    case table(version, name) do
      {:ok, table} -> table
      {:error, reason} -> raise ArgumentError, message: reason
    end
  end

  @spec version(t()) :: version()
  def version(%__MODULE__{version: version}) do
    version
  end

  @spec schema(t()) :: Schema.t()
  def schema(%__MODULE__{schema: schema}) do
    schema
  end

  @spec primary_keys(t(), schema(), name()) :: {:ok, [name()]} | {:error, String.t()}
  def primary_keys(%__MODULE__{primary_keys: pks}, sname, tname) do
    fetch_table_value(pks, {sname, tname})
  end

  @spec primary_keys(t(), table_ref()) :: {:ok, [name()]} | {:error, String.t()}
  def primary_keys(%__MODULE__{primary_keys: pks}, relation) do
    fetch_table_value(pks, relation)
  end

  @spec primary_keys!(t(), table_ref()) :: [name(), ...]
  def primary_keys!(version, relation) do
    case primary_keys(version, relation) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  def foreign_keys(%__MODULE__{} = version, {_, _} = relation, {_, _} = target) do
    fk_graph = fk_graph(version)

    case FkGraph.fetch_join_type(fk_graph, relation, target) do
      {:ok, {:many_to_one, {^relation, fks}, _}} ->
        {:ok, fks}

      _ ->
        {:error,
         "no foreign key found from #{Electric.Utils.inspect_relation(relation)} to #{Electric.Utils.inspect_relation(target)}"}
    end
  end

  @spec fk_graph(t()) :: FkGraph.t()
  def fk_graph(%__MODULE__{fk_graph: fk_graph}) do
    fk_graph
  end

  defp fetch_table_value(values, relation) do
    case Map.fetch(values, relation) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, "Table #{Electric.Utils.inspect_relation(relation)} not found"}
    end
  end

  def table_info(%__MODULE__{schema: schema}, oid_or_relation) do
    Schema.table_info(schema, oid_or_relation)
  end

  def table_info!(%__MODULE__{schema: schema}, oid_or_relation) do
    Schema.table_info!(schema, oid_or_relation)
  end

  def enums(%__MODULE__{schema: schema}) do
    {:ok, schema.enums}
  end
end
