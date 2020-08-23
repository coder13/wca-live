defmodule WcaLive.Factory do
  use ExMachina.Ecto, repo: WcaLive.Repo

  alias WcaLive.{Accounts, Competitions, Scoretaking}

  def user_factory do
    %Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      wca_user_id: sequence(:wca_user_id, & &1),
      name: "Sherlock Holmes",
      wca_id: nil,
      country_iso2: "GB",
      avatar_url: "https://example.com/avatar",
      avatar_thumb_url: "https://example.com/avatar-thumb",
      wca_teams: []
    }
  end

  def access_token_factory do
    %Accounts.AccessToken{
      access_token: "token",
      expires_at: hour_from_now(),
      refresh_token: "refresh-token",
      user: build(:user)
    }
  end

  def one_time_code_factory do
    %Accounts.OneTimeCode{
      code: "code",
      expires_at: hour_from_now(),
      user: build(:user)
    }
  end

  def competition_factory do
    %Competitions.Competition{
      wca_id: sequence(:wca_id, &"Competition#{&1}2020"),
      name: sequence(:name, &"Competition #{&1}"),
      short_name: sequence(:short_name, &"Comp #{&1}"),
      start_date: ~D[2020-04-10],
      end_date: ~D[2020-04-10],
      start_time: ~U[2020-04-10 08:00:00Z],
      end_time: ~U[2020-04-10 18:00:00Z],
      competitor_limit: nil,
      synchronized_at: hour_ago(),
      imported_by: build(:user)
    }
  end

  def person_factory do
    %Competitions.Person{
      wca_user_id: sequence(:wca_user_id, & &1),
      wca_id: nil,
      registrant_id: sequence(:registrant_id, & &1),
      name: "Sherlock Holmes",
      email: sequence(:email, &"email-#{&1}@example.com"),
      birthdate: ~D[2000-01-01],
      country_iso2: "GB",
      gender: "m",
      avatar_url: "https://example.com/avatar",
      avatar_thumb_url: "https://example.com/avatar-thumb",
      roles: [],
      competition: build(:competition)
    }
  end

  def registration_factory do
    %Competitions.Registration{
      wca_registration_id: sequence(:wca_registration_id, & &1),
      status: "accepted",
      guests: 0,
      comments: "Some information.",
      person: build(:person)
    }
  end

  def staff_member_factory do
    %Competitions.StaffMember{
      roles: ["organizer"],
      user: build(:user),
      competition: build(:competition)
    }
  end

  def competition_event_factory do
    %Competitions.CompetitionEvent{
      event_id: "333",
      competitor_limit: nil,
      qualification: nil,
      competition: build(:competition)
    }
  end

  def round_factory do
    %Scoretaking.Round{
      number: 1,
      format_id: "a",
      scramble_set_count: 2,
      advancement_condition: build(:advancement_condition),
      cutoff: build(:cutoff),
      time_limit: build(:time_limit),
      competition_event: build(:competition_event)
    }
  end

  def advancement_condition_factory do
    %Scoretaking.AdvancementCondition{
      type: "percent",
      level: 75
    }
  end

  def cutoff_factory do
    %Scoretaking.Cutoff{
      attempt_result: 6000,
      number_of_attempts: 2
    }
  end

  def time_limit_factory do
    %Scoretaking.TimeLimit{
      centiseconds: 10 * 6000,
      cumulative_round_wcif_ids: []
    }
  end

  def result_factory do
    %Scoretaking.Result{
      ranking: 1,
      best: 900,
      average: 900,
      average_record_tag: nil,
      single_record_tag: nil,
      advancing: true,
      entered_at: hour_ago(),
      attempts: build_list(5, :attempt),
      person: build(:person),
      entered_by: build(:user),
      round: build(:round)
    }
  end

  def attempt_factory do
    %Scoretaking.Attempt{
      result: 900,
      reconstruction: nil
    }
  end

  defp hour_from_now do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3600, :second)
  end

  defp hour_ago do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-3600, :second)
  end
end
