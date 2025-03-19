import 'package:armstrong/models/timeslot/timeslot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:armstrong/universal/blocs/appointment/appointment_new_bloc.dart';
import 'package:armstrong/widgets/navigation/appbar.dart';
import 'package:armstrong/widgets/forms/timeslot_form.dart';
import 'package:intl/intl.dart';

class TimeSlotListScreen extends StatefulWidget {
  final String specialistId;

  const TimeSlotListScreen({Key? key, required this.specialistId})
      : super(key: key);

  @override
  _TimeSlotListScreenState createState() => _TimeSlotListScreenState();
}

class _TimeSlotListScreenState extends State<TimeSlotListScreen> {
  @override
  void initState() {
    super.initState();
    _fetchTimeSlots();
  }

  void _fetchTimeSlots() {
    context.read<TimeSlotBloc>().add(
          GetAllSlotsEvent(
            specialistId: widget.specialistId,
          ),
        );
  }

  void _navigateToAddSlot() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSlotForm(specialistId: widget.specialistId),
      ),
    );

    if (result == true) {
      _fetchTimeSlots();
    }
  }

  Future<void> _navigateBack(BuildContext context) async {
    Navigator.pop(context, true);
    context.read<TimeSlotBloc>().add(ResetTimeSlotEvent());
  }

  void _navigateToEditSlot(TimeSlotModel slot) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSlotForm(
          slotId: slot.id,
          specialistId: widget.specialistId,
          initialDayOfWeek: slot.dayOfWeek,
          initialStartTime: slot.startTime,
          initialEndTime: slot.endTime,
        ),
      ),
    );

    print("Navigating to edit slot with ID: ${slot.id}");

    if (result == true) {
      _fetchTimeSlots(); // ✅ Refresh slot list after editing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TimeSlotBloc, TimeSlotState>(
        builder: (context, state) {
          if (state is TimeSlotLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimeSlotSuccess) {
            final slots = state.data as List<TimeSlotModel>;

            if (slots.isEmpty) {
              return const Center(
                child: Text("No available time slots. Please add new slots."),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                String formatTime(String time) {
                  final parsedTime = DateFormat("HH:mm").parse(time);
                  return DateFormat("h:mm a").format(parsedTime);
                }

                final formattedTime =
                    "${formatTime(slot.startTime)} - ${formatTime(slot.endTime)}";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      "${slot.dayOfWeek}, $formattedTime",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      slot.isBooked ? "Booked" : "Available",
                      style: TextStyle(
                        color: slot.isBooked ? Colors.red : Colors.green,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _navigateToEditSlot(slot);
                      },
                    ),
                  ),
                );
              },
            );
          } else if (state is TimeSlotFailure) {
            return Center(
              child: Text(
                "Error: ${state.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return const Center(child: Text("No time slots available."));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSlot,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
