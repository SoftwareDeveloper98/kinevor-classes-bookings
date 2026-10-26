import { EnvironmentProviders, Provider, makeEnvironmentProviders } from '@angular/core';
import {
  CLASSES_API_BASE_URL,
  CLASSES_GATEWAY,
  CLASSES_MEMBER_NAME,
  ClassesGateway,
  ClassesOptions,
} from './class.model';
import { ClassesFacade } from './classes.facade';
import { HttpClassesGateway } from './http-classes.gateway';

export function provideClassesBookings(options: ClassesOptions = {}): EnvironmentProviders {
  const providers: (Provider | EnvironmentProviders)[] = [
    { provide: CLASSES_GATEWAY, useClass: options.gateway ?? HttpClassesGateway },
    ClassesFacade,
  ];

  if (options.apiBaseUrl) {
    providers.push({ provide: CLASSES_API_BASE_URL, useValue: options.apiBaseUrl });
  }

  if (options.memberName) {
    providers.push({ provide: CLASSES_MEMBER_NAME, useValue: options.memberName });
  }

  return makeEnvironmentProviders(providers);
}
