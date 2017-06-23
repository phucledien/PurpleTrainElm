module App.Settings.Update exposing (..)

import App.Settings as Settings
import App.Maybe exposing (maybeToCommand)
import FetchAlertsAndSchedules exposing (fetchAlertsAndSchedules)
import UpsertInstallation exposing (upsertInstallation)
import Message exposing (..)
import Model exposing (Model)
import Types exposing (..)


receiveSettings : Model -> SettingsResult -> ( Model, Cmd Msg )
receiveSettings model settingsResult =
    case settingsResult of
        Err _ ->
            ( model, Cmd.none )

        Ok settings ->
            ( { model
                | dismissedAlertIds = Settings.dismissedAlertIds settings
                , selectedStop = Settings.stop settings
                , deviceToken = Settings.deviceToken settings
              }
            , onReceiveSettings settings
            )


onReceiveSettings : Settings -> Cmd Msg
onReceiveSettings settings =
    let
        maybeDeviceToken =
            Settings.deviceToken settings

        maybeStop =
            Settings.stop settings
    in
        Cmd.batch
            [ maybePromptForPushNotifications settings
            , maybeStop |> maybeToCommand fetchAlertsAndSchedules
            , Maybe.map2 upsertInstallation maybeStop maybeDeviceToken
                |> Maybe.withDefault Cmd.none
            ]


maybePromptForPushNotifications : Settings -> Cmd Msg
maybePromptForPushNotifications settings =
    if Settings.promptedForCancellationsNotifications settings then
        Cmd.none
    else
        prePromptForPushNotifications settings


prePromptForPushNotifications : Settings -> Cmd Msg
prePromptForPushNotifications settings =
    case ( Settings.deviceToken settings, Settings.stop settings ) of
        ( Just token, Just stop ) ->
            Cmd.none

        _ ->
            Cmd.none



-- TODO:
-- After loading settings:
-- If the user has not been prompted yet:
--
