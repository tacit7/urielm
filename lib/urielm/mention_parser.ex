defmodule Urielm.MentionParser do
  @moduledoc """
  Parses @username mentions from text and creates mention records.
  """

  alias Urielm.Repo
  alias Urielm.Accounts
  alias Urielm.Forum.Mention

  @mention_regex ~r/@([a-z0-9_-]{3,20})\b/i

  @doc """
  Extract all @username mentions from text.
  Returns a list of unique usernames (without the @).
  """
  def extract_mentions(text) when is_binary(text) do
    @mention_regex
    |> Regex.scan(text)
    |> Enum.map(fn [_full, username] -> String.downcase(username) end)
    |> Enum.uniq()
  end

  def extract_mentions(_), do: []

  @doc """
  Create mention records for all valid users mentioned in the text.
  Returns {:ok, count} where count is number of mentions created.
  """
  def process_mentions(text, mentioner_id, target_type, target_id) do
    usernames = extract_mentions(text)

    mentions_created =
      Enum.reduce(usernames, 0, fn username, acc ->
        case Accounts.get_user_by_username(username) do
          nil ->
            acc

          user ->
            # Don't create mention if user is mentioning themselves
            if user.id == mentioner_id do
              acc
            else
              case create_mention(user.id, mentioner_id, target_type, target_id) do
                {:ok, _mention} -> acc + 1
                {:error, _} -> acc
              end
            end
        end
      end)

    {:ok, mentions_created}
  end

  defp create_mention(user_id, mentioner_id, target_type, target_id) do
    %Mention{}
    |> Mention.changeset(%{
      user_id: user_id,
      mentioner_id: mentioner_id,
      target_type: target_type,
      target_id: target_id
    })
    |> Repo.insert(on_conflict: :nothing)
  end
end
