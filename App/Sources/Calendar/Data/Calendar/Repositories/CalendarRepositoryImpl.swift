//
//  CalendarRepository.swift
//  Lunar
//
//  Created by hbkim on 2023/11/17.
//  Copyright © 2023 theo. All rights reserved.
//

final class CalendarRepositoryImpl: CalendarRepository {
  private let local: CalendarLocalDataSource
  private let remoteDataSources: [CalendarRemoteDataSource]

  init(local: CalendarLocalDataSource, remoteDataSources: [CalendarRemoteDataSource]) {
    self.local = local
    self.remoteDataSources = remoteDataSources
  }

  func events() -> [Event] {
    return local.findAll()
  }

  func newEvent(event: Event, providers: [CalendarProvider]) throws -> Event {
    let newEvent = try local.insert(event: event)

    if event.syncCalendar {
      for provider in providers {
        let remoteDataSource = findDataSource(provider: provider)
        try remoteDataSource?.save(event: newEvent)
      }
    }
    return newEvent
  }

  func updateEvent(event: Event, providers: [CalendarProvider]) throws -> Event {
    guard let id = event.id else {
      throw CalendarError.eventIdNotExists
    }

    let old = try local.find(id: id)
    let newEvent = try local.update(event: event)
    if event.syncCalendar {
      for provider in providers {
        let remoteDataSource = findDataSource(provider: provider)
        try remoteDataSource?.update(old: old, new: newEvent)
      }
    } else if old.syncCalendar {
      for provider in providers {
        let remoteDataSource = findDataSource(provider: provider)
        try remoteDataSource?.remove(event: old)
      }
    }
    return newEvent
  }

  func deleteEvent(_ id: String, providers: [CalendarProvider]) throws {
    let event = try local.delete(id: id)

    for provider in providers {
      let remoteDataSource = findDataSource(provider: provider)
      try remoteDataSource?.remove(event: event)
    }
  }

  func deleteAll(providers: [CalendarProvider]) throws {
    for event in events() {
      if let id = event.id {
        try deleteEvent(id, providers: providers)
      }
    }
  }

  func verifyAuthorizationStatus(provider: CalendarProvider) async -> Bool {
    let remoteDataSource = findDataSource(provider: provider)
    return await remoteDataSource?.verifyAuthorizationStatus() ?? false
  }

  func syncCalendar(provider: CalendarProvider) throws {
    let events = local.findAll()

    let remoteDataSource = findDataSource(provider: provider)
    for event in events where event.syncCalendar {
      try? remoteDataSource?.save(event: event)
    }
  }

  func unsyncCalendar(provider: CalendarProvider) throws {
    let remoteDataSource = findDataSource(provider: provider)
    try remoteDataSource?.removeAll()
  }
}

private extension CalendarRepositoryImpl {
  func findDataSource(provider: CalendarProvider) -> CalendarRemoteDataSource? {
    return remoteDataSources.first(where: { $0.provider == provider })
  }
}
