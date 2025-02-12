defmodule WcaLiveWeb.CompetitionControllerTest do
  use WcaLiveWeb.ConnCase

  import WcaLive.Factory

  alias WcaLive.Repo

  describe "show_wcif" do
    @tag :signed_in
    test "returns WCIF when authorized", %{conn: conn, current_user: current_user} do
      competition = insert(:competition, wca_id: "WC2019")
      insert(:staff_member, competition: competition, user: current_user, roles: ["delegate"])

      conn = get(conn, "/api/competitions/#{competition.id}/wcif")

      body = json_response(conn, 200)
      assert %{"formatVersion" => "1.0", "id" => "WC2019"} = body
    end

    test "returns error when not signed in", %{conn: conn} do
      competition = insert(:competition, wca_id: "WC2019")

      conn = get(conn, "/api/competitions/#{competition.id}/wcif")

      body = json_response(conn, 403)
      assert body == %{"error" => "access denied"}
    end

    @tag :signed_in
    test "returns error when not authorized", %{conn: conn} do
      competition = insert(:competition, wca_id: "WC2019")

      conn = get(conn, "/api/competitions/#{competition.id}/wcif")

      body = json_response(conn, 403)
      assert body == %{"error" => "access denied"}
    end
  end

  describe "enter_attempt" do
    test "returns error when no token is given", %{conn: conn} do
      competition = insert(:competition)
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => 1000
      }

      conn = post(conn, "/api/enter-attempt", body)

      assert %{"error" => "no authorization token provided"} = json_response(conn, 401)
    end

    test "returns error when non-existent token is given", %{conn: conn} do
      competition = insert(:competition)
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => 1000
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer nonexistent")
        |> post("/api/enter-attempt", body)

      assert %{"error" => "the provided token is not valid"} = json_response(conn, 401)
    end

    @tag :signed_in
    test "returns error when the token is for a different competition",
         %{conn: conn, current_user: current_user} do
      competition = insert(:competition)
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      scoretaking_token = insert(:scoretaking_token, user: current_user)

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => 1000
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{scoretaking_token.token}")
        |> post("/api/enter-attempt", body)

      assert %{"error" => "the provided token does not grant access to this competition"} =
               json_response(conn, 401)
    end

    @tag :signed_in
    test "returns error when the user does not have access to the competition",
         %{conn: conn, current_user: current_user} do
      competition = insert(:competition)
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      scoretaking_token = insert(:scoretaking_token, competition: competition, user: current_user)

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => 1000
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{scoretaking_token.token}")
        |> post("/api/enter-attempt", body)

      assert %{"error" => "the token user no longer have access to this competition"} =
               json_response(conn, 401)
    end

    test "returns error on incomplete payload", %{conn: conn} do
      competition = insert(:competition)

      body = %{
        "competitionWcaId" => competition.wca_id
      }

      conn = post(conn, "/api/enter-attempt", body)

      assert %{"error" => "invalid payload"} = json_response(conn, 400)
    end

    @tag :signed_in
    test "updates result", %{conn: conn, current_user: current_user} do
      competition = insert(:competition)
      insert(:staff_member, competition: competition, user: current_user, roles: ["delegate"])
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      scoretaking_token = insert(:scoretaking_token, competition: competition, user: current_user)

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => 1000
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{scoretaking_token.token}")
        |> post("/api/enter-attempt", body)

      json_response(conn, 200)

      result = Repo.reload(result)
      assert current_user.id == result.entered_by_id
      assert [1000] == Enum.map(result.attempts, & &1.result)
    end

    @tag :signed_in
    test "returns errors on invalid update", %{conn: conn, current_user: current_user} do
      competition = insert(:competition)
      insert(:staff_member, competition: competition, user: current_user, roles: ["delegate"])
      competition_event = insert(:competition_event, competition: competition)
      round = insert(:round, competition_event: competition_event)
      result = insert(:result, round: round, attempts: [])

      scoretaking_token = insert(:scoretaking_token, competition: competition, user: current_user)

      body = %{
        "competitionWcaId" => competition.wca_id,
        "eventId" => "333",
        "roundNumber" => 1,
        "registrantId" => result.person.registrant_id,
        "attemptNumber" => 1,
        "attemptResult" => nil
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{scoretaking_token.token}")
        |> post("/api/enter-attempt", body)

      assert %{"errors" => ["result can't be blank"]} =
               json_response(conn, 422)
    end
  end
end
