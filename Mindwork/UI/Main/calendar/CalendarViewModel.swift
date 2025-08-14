//
//  HistoryViewModel.swift
//  Tendria
//
//  Created by Yakup Kavak on 2.02.2025.
//

import Foundation

import FirebaseFirestore

class CalendarViewModel: BaseViewModel{
    @Published var selectedDay: Date = .now
    @Published var sortAscending = true
    @Published private(set) var events: [EventDocumentModel] = []
    
    private var listener: ListenerRegistration?
    private let calendar = Calendar.current
    
    func startListening() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

            guard let relationId = try? await RelationRepository.shared.getRelationId() else { return }

            // 1) Listener’ı arka planda oluştur
            let reg = FirestorageManager.shared.listenEvents(
                relationId: relationId
            ) { [weak self] list in
                // 3) Snapshot geldi → UI güncelle
                Task { @MainActor in        // main hop
                    self?.events = list
                }
            }

            // 2) Oluşturulan listener’ı ana aktörde sakla
            await MainActor.run {
                self.listener = reg
            }
        }
    }
    
    deinit { listener?.remove() }
    
    // Seçili güne filtre + sıralama
    var dayEvents: [EventDocumentModel] {
        events
            .filter { calendar.isDate($0.eventDate.dateValue(), inSameDayAs: selectedDay) }
            .sorted(by: { lhs, rhs in
                        sortAscending
                ? lhs.startHour.dateValue() < rhs.startHour.dateValue()
                        : rhs.startHour.dateValue() > rhs.startHour.dateValue()
                    })
    }
    
    // UI çağrıları
    func toggleSort() { sortAscending.toggle() }
    
    func moveWeek(by delta: Int) {
        if let d = calendar.date(byAdding: .day, value: delta*7, to: selectedDay) {
            selectedDay = d
        }
    }
    
    func delete(_ ev: EventDocumentModel) {
        getDataCall {
            try await FirestorageManager.shared.deleteEvent(ev)
        } onSuccess: { _ in
            print("")
        } onLoading: {
            print("")
        } onError: { _ in
            print("")
        }
    }
}
